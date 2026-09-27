#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which calls of a sub to itself the policy reports, and which it leaves alone

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not.

The cases that matter are the ways a sub can reach itself, by name, by a
method on its own invocant, or through C<__SUB__>, and the ways that look like
a call and are not one: C<goto>, a reference, another object, a nested sub.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Subroutines::ProhibitTailRecursion;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Subroutines::ProhibitTailRecursion$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

sub check_table {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
}

check_table(
    'a sub that calls itself',
    'by name, in the tail'                  => [ 1, q{sub f { my ($n) = @_; return 0 if !$n; return f( $n - 1 ); }} ],
    'by name, with no parens'               => [ 1, q{sub f { my ($n) = @_; return $n ? f $n - 1 : 0; }} ],
    'by name, in a loop'                    => [ 1, q{sub walk { my ($n) = @_; walk($_) for kids($n); return; }} ],
    'by name, in the block of a map'        => [ 1, q{sub walk { my ($n) = @_; return map { walk($_) } kids($n); }} ],
    'by name, in an anonymous sub'          => [ 1, q{sub walk { my ($n) = @_; my $c = sub { walk(@_) }; return $c->($n); }} ],
    'twice, reported twice'                 => [ 2, q{sub fib { my ($n) = @_; return $n < 2 ? $n : fib( $n - 1 ) + fib( $n - 2 ); }} ],
    'with &, and parens'                    => [ 1, q{sub f { my ($n) = @_; return $n ? &f( $n - 1 ) : 0; }} ],
    'with &, passing @_ on'                 => [ 1, q{sub f { shift; return @_ ? &f : 0; }} ],
    'by its full name in its own package'   => [ 1, q{package Foo; sub f { my ($n) = @_; return $n ? Foo::f( $n - 1 ) : 0; }} ],
    'in main, by its full name'             => [ 1, q{sub f { my ($n) = @_; return $n ? main::f( $n - 1 ) : 0; }} ],
    'declared by its full name'             => [ 1, q{sub Foo::f { my ($n) = @_; return $n ? f( $n - 1 ) : 0; }} ],
    'as a method on $self'                  => [ 1, q{sub walk { my ( $self, $n ) = @_; return map { $self->walk($_) } kids($n); }} ],
    'as a method on $class'                 => [ 1, q{sub walk { my ( $class, $n ) = @_; return $n ? $class->walk( $n - 1 ) : 0; }} ],
    q{as a method, by its full name}        => [ 1, q{package Foo; sub walk { my ( $self, $n ) = @_; return $n ? $self->Foo::walk( $n - 1 ) : 0; }} ],
    'as a method on __PACKAGE__'            => [ 1, q{sub walk { my ( undef, $n ) = @_; return $n ? __PACKAGE__->walk( $n - 1 ) : 0; }} ],
    'through __SUB__'                       => [ 1, q{use feature 'current_sub'; my $w = sub { __SUB__->($_) for kids( $_[0] ); };} ],
    'through &{ __SUB__ }'                  => [ 1, q{use feature 'current_sub'; my $w = sub { &{ __SUB__ }($_) for kids( $_[0] ); };} ],
    'through __SUB__ in a named sub'        => [ 1, q{use feature 'current_sub'; sub f { my ($n) = @_; return $n ? __SUB__->( $n - 1 ) : 0; }} ],
    'in the outer sub, beside a nested one' => [ 1, q{sub f { sub g { return 1 } return f(); }} ],
);

check_table(
    'not a call of a sub to itself',
    'goto &name'                            => [ 0, q{sub f { my ($n) = @_; return 0 if !$n; @_ = ( $n - 1 ); goto &f; }} ],
    'goto __SUB__'                          => [ 0, q{use feature 'current_sub'; my $w = sub { return 0 if !$_[0]; @_ = ( $_[0] - 1 ); goto __SUB__; };} ],
    'a reference to itself'                 => [ 0, q{sub f { return \&f; }} ],
    '__SUB__ as a value'                    => [ 0, q{use feature 'current_sub'; my $w = sub { return __SUB__; };} ],
    'a call to another sub'                 => [ 0, q{sub f { return g(1); }} ],
    'a sub whose name contains its own'     => [ 0, q{sub f { return ff(1); }} ],
    'the same name in another package'      => [ 0, q{package Foo; sub f { return Bar::f(1); }} ],
    'its name as a hash key'                => [ 0, q{sub f { my %h = ( f => 1 ); return $h{f}; }} ],
    'its name as a string'                  => [ 0, q{sub f { return 'f'; }} ],
    'the same method on another object'     => [ 0, q{sub walk { my ( $self, $kid ) = @_; return $kid->walk; }} ],
    'the method of the parent class'        => [ 0, q{sub new { my ( $class, @args ) = @_; return $class->SUPER::new(@args); }} ],
    'another method on $self'               => [ 0, q{sub walk { my ($self) = @_; return $self->step; }} ],
    'a nested sub that calls the outer one' => [ 0, q{sub f { sub g { return f() } return 1; }} ],
    'a forward declaration'                 => [ 0, q{sub f;} ],
    'a call from outside the sub'           => [ 0, q{sub f { return 1 } f(); f();} ],
    'a sub that calls another, in a cycle'  => [ 0, q{sub f { return g() } sub g { return f() }} ],
);

is_deeply( [ warnings { $critic->critique( \q{sub f { return f() }} ) } ], [], q{and no warnings on the way} );

done_testing();
