#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

{
    package My::Package::Stash;
    use strict;
    use warnings;

    use base 'Package::Stash';

    use Symbol 'gensym';

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->{namespace} = {};
        return $self;
    }

    sub namespace { shift->{namespace} }

    sub add_symbol {
        my ($self, $variable, $initial_value) = @_;

        (my $name = $variable) =~ s/^[\$\@\%\&]//;

        my $glob = gensym();
        *{$glob} = $initial_value if defined $initial_value;
        $self->namespace->{$name} = *{$glob};
    }
}

# No actually package Foo exists :)
my $foo_stash = My::Package::Stash->new('Foo');

isa_ok($foo_stash, 'My::Package::Stash');
isa_ok($foo_stash, 'Package::Stash');

ok(!defined($Foo::{foo}), '... the %foo slot has not been created yet');
ok(!$foo_stash->has_symbol('%foo'), '... the foo_stash agrees');

is(exception {
    $foo_stash->add_symbol('%foo' => { one => 1 });
}, undef, '... the %foo symbol is created succcessfully');

ok(!defined($Foo::{foo}), '... the %foo slot has not been created in the actual Foo package');
ok($foo_stash->has_symbol('%foo'), '... the foo_stash agrees');

my $foo = $foo_stash->get_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

$foo->{two} = 2;

is($foo, $foo_stash->get_symbol('%foo'), '... our %foo is the same as the foo_stashs');

ok(!defined($Foo::{bar}), '... the @bar slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('@bar' => [ 1, 2, 3 ]);
}, undef, '... created @Foo::bar successfully');

ok(!defined($Foo::{bar}), '... the @bar slot has still not been created');

ok(!defined($Foo::{baz}), '... the %baz slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('%baz');
}, undef, '... created %Foo::baz successfully');

ok(!defined($Foo::{baz}), '... the %baz slot has still not been created');

done_testing;
