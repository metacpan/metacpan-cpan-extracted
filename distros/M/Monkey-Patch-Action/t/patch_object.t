#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Monkey::Patch::Action qw(patch_object);

package Foo;

sub new { my $pkg = shift; bless {}, $pkg }
sub m1 { my $self = shift; "Foo's m1" }

package Bar;

our @ISA = qw(Foo);

package main;

my @h;

my $foo1 = Foo->new;
my $foo2 = Foo->new;

test_patch(
    name                => 'non-object -> dies',
    patch_args          => [[], 'add' => sub { }],
    patch_dies          => 1,
);

test_patch(
    name                => 'unknown action -> dies',
    patch_args          => [$foo1, 'm2', 'explode' => sub { }],
    patch_dies          => 1,
);

# XXX test: add to existant -> dies

test_patch(
    name                => 'add without mentioning code -> dies',
    patch_args          => [$foo1, 'm2', 'add'],
    patch_dies          => 1,
);

test_patch(
    name                => 'add',
    non_patched_object  => $foo2,
    patch_args          => [$foo1, 'm2', 'add', sub { "monkey" }],
    tests_before_patch  => [
        {func=>'Foo::m2', dies=>1},
    ],
    tests_after_patch   => [
        {func=>'Foo::m2', res=>"monkey"},
    ],
);

# XXX test: replace to non-existant -> dies

test_patch(
    name                => 'replace without mentioning code -> dies',
    patch_args          => [$foo1, 'm1', 'replace'],
    patch_dies          => 1,
);

test_patch(
    name                => 'replace',
    non_patched_object  => $foo2,
    patch_args          => [$foo1, 'm1', 'replace', sub { "duck" }],
    tests_before_patch  => [
        {func=>'Foo::m1', res=>"Foo's m1"},
    ],
    tests_after_patch   => [
        {func=>'Foo::m1', res=>"duck"},
    ],
);

test_patch(
    name                => 'add_or_replace',
    non_patched_object  => $foo1,
    patch_args          => [$foo2, 'm1', 'add_or_replace', sub { "punch" }],
    tests_before_patch  => [
        {func=>'Foo::m1', res=>"Foo's m1"},
    ],
    tests_after_patch   => [
        {func=>'Foo::m1', res=>"punch"},
    ],
);

test_patch(
    name                => 'delete mentioning code -> dies',
    patch_args          => [$foo1, 'm1', 'delete', sub { }],
    patch_dies          => 1,
);

test_patch(
    name                => 'delete',
    non_patched_object  => $foo1,
    patches_args        => [
        [$foo2, m1 => 'delete'],
        [$foo2, fd => 'delete'],
    ],
    tests_before_patch  => [
        {func=>'Foo::m1', res=>"Foo's m1"},
        {func=>'Foo::fd', dies=>1},
    ],
    tests_after_patch   => [
        {func=>'Foo::m1', dies=>1},
        {func=>'Foo::fd', dies=>1},
    ],
);

# XXX test: wrap non-existant -> dies

goto DONE_TESTING;

test_patch(
    name                => 'wrap',
    non_patched_object  => $foo1,
    patch_args          => [$foo2 => m1 => wrap => sub {
                                my $ctx = shift;
                                "wrap $ctx->{package} $ctx->{subname} ".
                                    join(",", @{$ctx->{extra}}).": ".
                                        $ctx->{orig}->(@_);
                            }, 1, 2],
    tests_before_patch  => [
        {func=>'Foo::m1', res=>"Foo's m1"},
    ],
    tests_after_patch   => [
        {func=>'Foo::m1', res=>"wrap Foo m1 1,2: Foo's m1"},
    ],
);

# XXX test: stacked patches

DONE_TESTING:
done_testing;

sub unpatch {
    pop @h while @h;
}

sub _tests {
    my ($obj, $tests, $name) = @_;

    local $main::_obj = $obj;

    subtest $name => sub {
        for my $t (@$tests) {
            my $code = "\$main::_obj->$t->{func}(".join(",",map{"'$_'"} @{$t->{args} // []}).")";
            my $res;
            subtest $code => sub {
                eval "\$res = $code;";
                my $e = $@;
                if ($t->{dies}) {
                    ok($e, "dies");
                    return;
                } else {
                    ok(!$e, "doesn't die") or do { diag $e; return };
                }
                if (defined $t->{res}) {
                    is($res, $t->{res}, "result");
                }
            };
        }
    };
}

sub test_patch {
    my %args = @_;

    subtest $args{name} => sub {

        my $obj;
        if ($args{patch_args}) {
            $obj = $args{patch_args}[0];
        } else {
            $obj = $args{patches_args}[0][0];
        }

        my $npobj = $args{non_patched_object};

        if ($args{tests_before_patch}) {
            _tests($obj, $args{tests_before_patch}, "tests before patch (to patched object)");
            _tests($npobj, $args{tests_before_patch}, "tests before patch (to non-patched object)")
                if $npobj;
        }

        eval {
            if ($args{patch_args}) {
                push @h, patch_object(@{ $args{patch_args} });
            }
            if ($args{patches_args}) {
                push @h, patch_object(@$_) for @{ $args{patches_args} };
            }
        };
        my $e = $@;
        if ($args{patch_dies}) {
            ok($e, "patch dies");
            return;
        } else {
            ok(!$e, "patch doesn't die") or do { diag $e; return };
        }

        if ($args{tests_after_patch}) {
            _tests($obj, $args{tests_after_patch}, "tests after patch (to patched object)");
        }
        if ($args{tests_before_patch}) {
            _tests($npobj, $args{tests_before_patch}, "tests after patch (to non-patched object)")
                if $npobj;
        }

        if ($args{unpatch} // 1) {
            unpatch();
            my $t = $args{tests_after_unpatch} // 1;
            $t = $args{tests_before_patch} if !ref($t);
            _tests($obj, $t, "tests after unpatch (to patched object)") if $t;
        }

    };
}
