#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Sub::Call::Tail' => qw(:all);

sub bar { (caller(1))[3] }

sub foo {
    tail bar();
}

sub baz {
    my $self = shift;
    tail $self->bar();
}

sub args { "@_" }

sub foo_args {
    tail args( hello => @_ );
}

sub oo_args {
    my $self = shift;
    tail $self->args( hello => @_ );
}

sub oo_args_no_lex {
    tail $_[0]->args( hello => @_[1 .. $#_] );
}

sub oo_args_temp {
    tail shift->args( hello => @_ );
}

sub blah {
    @_ = qw(blah blah);
    tail args("foo");
}

sub blooh {
    @_ = qw(blah blah);
    my $x = 42;
    tail args($x);
}

sub AUTOLOAD { our $AUTOLOAD }

sub auto {
    no strict 'subs';
    tail something_autoloaded();
}

sub anon_immortal {
    tail((sub { 3 })->());
}

sub anon {
    my $x = 3;
    tail((sub { $x })->());
}

sub tmps {
    my $y = "";
    tail args(map { $_ . $y } @_);
}

sub error {
    no strict 'subs';
    package blerghch; # AUTOLOAD
    ::tail does_not_exist();
}

sub not_sub {
    my $sub = [];
    tail $sub->();
}

sub loose {
    no strict 'refs';
    my $sub = "main::args";
    tail $sub->(@_);
}

sub tests {
    my $foo = bless {};
    my $copy = \$foo;

    is( bar(), "main::tests", "bar" );
    is( foo(), "main::tests", "foo has a tailcall to bar" );
    is( $foo->baz, "main::tests", "OO tail call" );

    is( args(qw(foo bar)), "foo bar", "args for normal call" );
    is( foo_args(qw(foo bar)), "hello foo bar", "args for tail call" );
    is( $foo->oo_args(qw(foo bar)), "$foo hello foo bar", "oo args for tail call" );
    is( $foo->oo_args_no_lex(qw(foo bar)), "$foo hello foo bar", "oo args for tail call without lex" );
    is( $foo->oo_args_temp(qw(foo bar)), "$foo hello foo bar", "oo args for tail call without var" );

    is( blah(), "foo", 'reified @_ gets dropped' );
    is( blooh(), 42, 'reified @_ recreated' );

    is( auto(), "main::something_autoloaded", "autoload" );

    is( anon_immortal(), 3, "anon sub (not cloned)" );
    is( anon(), 3, "anon sub" );

    is( tmps(qw(foo bar)), "foo bar", "tmps" );

    is( loose(qw(oh hai)), "oh hai", "no strict" );

    eval { error() };
    like( $@, qr/does_not_exist/, "error on nonexistent sub" );

    eval { not_sub() };
    like( $@, qr/CODE/, "error on incorrect data type" );
}

tests();

done_testing;

# ex: set sw=4 et:

