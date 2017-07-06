#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Monkey::Patch::Action qw(patch_package);

package Foo;

sub f1 { "Foo's f1" }
sub f2 { "Foo's f2, args=".join(",",@_) }
sub m1 { my $self = shift; "Foo's m1, args=".join(",",@_) }

package Bar;

our @ISA = qw(Foo);

package main;

my @h;

test_patch(
    name                => 'unknown action -> dies',
    patch_args          => [Foo => f1 => foo => sub { }],
    patch_dies          => 1,
);

test_patch(
    name                => 'add existant -> dies',
    patch_args          => [Foo => f1 => add => sub {}],
    patch_dies          => 1,
);
test_patch(
    name                => 'add',
    patch_args          => [Foo => fa => add => sub { "monkey" }],
    tests_before_patch  => [
        {func=>'Foo::fa', dies=>1},
    ],
    tests_after_patch   => [
        {func=>'Foo::fa', res=>"monkey"},
    ],
);

test_patch(
    name                => 'replace non-existant -> dies',
    patch_args          => [Foo => fr => replace => sub {}],
    patch_dies          => 1,
);
test_patch(
    name                => 'replace',
    patch_args          => [Foo => f1 => replace => sub { "duck" }],
    tests_before_patch  => [
        {func=>'Foo::f1', res=>"Foo's f1"},
    ],
    tests_after_patch   => [
        {func=>'Foo::f1', res=>"duck"},
    ],
);

test_patch(
    name                => 'add_or_replace',
    patches_args        => [
        [Foo => f1 => add_or_replace => sub { "punch" }],
        [Foo => fa => add_or_replace => sub { "patch" }],
    ],
    tests_before_patch  => [
        {func=>'Foo::f1', res=>"Foo's f1"},
        {func=>'Foo::fa', dies=>1},
    ],
    tests_after_patch   => [
        {func=>'Foo::f1', res=>"punch"},
        {func=>'Foo::fa', res=>"patch"},
    ],
);

test_patch(
    name                => 'delete mentioning code -> dies',
    patch_args          => [Foo => f1 => delete => sub { }],
    patch_dies          => 1,
);

test_patch(
    name                => 'delete',
    patches_args        => [
        [Foo => f1 => 'delete'],
        [Foo => fd => 'delete'],
    ],
    tests_before_patch  => [
        {func=>'Foo::f1', res=>"Foo's f1"},
        {func=>'Foo::fd', dies=>1},
    ],
    tests_after_patch   => [
        {func=>'Foo::f1', dies=>1},
        {func=>'Foo::fd', dies=>1},
    ],
);

test_patch(
    name                => 'wrap non-existant -> dies',
    patch_args          => [Foo => fw => wrap => sub {}],
    patch_dies          => 1,
);
test_patch(
    name                => 'wrap',
    patch_args          => [Foo => f1 => wrap => sub {
                                my $ctx = shift;
                                "wrap $ctx->{package} $ctx->{subname} ".
                                    join(",", @{$ctx->{extra}}).": ".
                                        $ctx->{orig}->(@_);
                            }, 1, 2],
    tests_before_patch  => [
        {func=>'Foo::f1', res=>"Foo's f1"},
    ],
    tests_after_patch   => [
        {func=>'Foo::f1', res=>"wrap Foo f1 1,2: Foo's f1"},
    ],
);

subtest "stacked: wrap1 + wrap2 (wrap2 unapplied first)" => sub {
    test_patch(
        patches_args        => [
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap1: ".$ctx->{orig}->(@_);
             }],
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap2: ".$ctx->{orig}->(@_);
             }],
        ],
        tests_before_patch  => [
            {func=>'Foo::f1', res=>"Foo's f1"},
        ],
        tests_after_patch   => [
            {func=>'Foo::f1', res=>"wrap2: wrap1: Foo's f1"},
        ],
        unpatch             => 0,
    );
    undef $h[1];
    _tests([
        {func=>'Foo::f1', res=>"wrap1: Foo's f1"},
    ]);
    unpatch();
    _tests([
        {func=>'Foo::f1', res=>"Foo's f1"},
    ]);
};

subtest "stacked: wrap1 + wrap2 (wrap1 unapplied first)" => sub {
    test_patch(
        patches_args        => [
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap1: ".$ctx->{orig}->(@_);
             }],
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap2: ".$ctx->{orig}->(@_);
             }],
        ],
        tests_before_patch  => [
            {func=>'Foo::f1', res=>"Foo's f1"},
        ],
        tests_after_patch   => [
            {func=>'Foo::f1', res=>"wrap2: wrap1: Foo's f1"},
        ],
        unpatch             => 0,
    );
    undef $h[0];
    _tests([
        {func=>'Foo::f1', res=>"wrap2: Foo's f1"},
    ]);
    unpatch();
    _tests([
        {func=>'Foo::f1', res=>"Foo's f1"},
    ]);
};

subtest "stacked: del + add + wrap (unapply ordered)" => sub {
    test_patch(
        patches_args        => [
            [Foo => f1 => 'delete'],
            [Foo => f1 => add => sub { "plone" }],
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap: ".$ctx->{orig}->(@_);
             }],
        ],
        tests_before_patch  => [
            {func=>'Foo::f1', res=>"Foo's f1"},
        ],
        tests_after_patch   => [
            {func=>'Foo::f1', res=>"wrap: plone"},
        ],
        unpatch             => 0,
    );
    undef $h[2];
    _tests([
        {func=>'Foo::f1', res=>"plone"},
    ]);
    undef $h[1];
    _tests([
        {func=>'Foo::f1', dies=>1},
    ]);
    unpatch();
    _tests([
        {func=>'Foo::f1', res=>"Foo's f1"},
    ]);
};

subtest "stacked: del + add + wrap (add unapplied -> conflict)" => sub {
    test_patch(
        patches_args        => [
            [Foo => f1 => 'delete'],
            [Foo => f1 => add => sub { "plone" }],
            [Foo => f1 => wrap => sub {
                 my $ctx = shift;
                 "wrap: ".($ctx->{orig}->(@_) // "X");
             }],
        ],
        tests_before_patch  => [
            {func=>'Foo::f1', res=>"Foo's f1"},
        ],
        tests_after_patch   => [
            {func=>'Foo::f1', res=>"wrap: plone"},
        ],
        unpatch             => 0,
    );
    undef $h[1];
    _tests([
        {func=>'Foo::f1', res=>"wrap: X"},
    ]);
    unpatch();
    _tests([
        {func=>'Foo::f1', res=>"Foo's f1"},
    ]);
};

# XXX test: calling parent's method from wrapper

# XXX test: demo patching object

DONE_TESTING:
done_testing();

sub unpatch {
    pop @h while @h;
}

sub _tests {
    my ($tests, $name) = @_;

    subtest $name => sub {
        for my $t (@$tests) {
            my $code = "$t->{func}(".join(",",map{"'$_'"} @{$t->{args} // []}).")";
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

        _tests($args{tests_before_patch}, "tests before patch")
            if $args{tests_before_patch};

        eval {
            if ($args{patch_args}) {
                push @h, patch_package(@{ $args{patch_args} });
            }
            if ($args{patches_args}) {
                push @h, patch_package(@$_) for @{ $args{patches_args} };
            }
        };
        my $e = $@;
        if ($args{patch_dies}) {
            ok($e, "patch dies");
            return;
        } else {
            ok(!$e, "patch doesn't die") or do { diag $e; return };
        }

        _tests($args{tests_after_patch}, "tests after patch")
            if $args{tests_after_patch};

        if ($args{unpatch} // 1) {
            unpatch();
            my $t = $args{tests_after_unpatch} // 1;
            $t = $args{tests_before_patch} if !ref($t);
            _tests($t, "tests after unpatch") if $t;
        }

    };
}
