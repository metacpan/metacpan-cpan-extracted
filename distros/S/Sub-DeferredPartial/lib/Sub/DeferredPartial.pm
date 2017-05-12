package Sub::DeferredPartial;

our $VERSION = '0.01';

use Sub::DeferredPartial::Attributes();
use Sub::DeferredPartial::Op::Nullary();
use Sub::DeferredPartial::Op::Unary();
use Sub::DeferredPartial::Op::Binary();
use Carp;

use overload
  '&{}'    => 'Subify'
, '""'     => 'Describe'
, nomethod => 'NoMethod'
;
# -----------------------------------------------------------------------------
sub import
# -----------------------------------------------------------------------------
{
  my $class  = shift;
  my $Name   = shift || 'defer';
  my $Caller = caller;

  *{"$Caller\::$Name"} = \&Defer;
  Sub::DeferredPartial::Attributes->import( $Caller );
}
# -----------------------------------------------------------------------------
sub new
# -----------------------------------------------------------------------------
{
  my $class = shift;
  my $Sub   = shift;
  my $Free  = shift;
  my $Bound = shift || {};

  bless { Sub => $Sub, F => $Free, B => $Bound } => $class;
}
# -----------------------------------------------------------------------------
sub Subify
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return sub { return @_ ? $self->Apply( @_ ) : $self->Eval };
}
# -----------------------------------------------------------------------------
sub Apply
# -----------------------------------------------------------------------------
{
  my $self = shift;
  my %Args = @_;
  my %F    = %{$self->{F}};
  my %B    = %{$self->{B}};

  while ( my ( $k, $v ) = each %Args )
  {
    confess "Bound parameter: $k" if     exists $B{$k}; $B{$k} = $v;
    confess "Wrong parameter: $k" unless exists $F{$k}; delete $F{$k};
  }
  return ref( $self )->new( $self->{Sub}, \%F, \%B );
}
# -----------------------------------------------------------------------------
sub Eval
# -----------------------------------------------------------------------------
{
  my $self = shift;

  confess "Free parameter: $_" for keys %{$self->{F}};

  return $self->{Sub}->( %{$self->{B}} );
}
# -----------------------------------------------------------------------------
sub Free
# -----------------------------------------------------------------------------
{
  my $self = shift;

  return $self->{F};
}
# -----------------------------------------------------------------------------
sub Describe
# -----------------------------------------------------------------------------
{
  my $self = shift;
  my @s;

  while ( my ( $k, $v ) = each %{$self->{B}} ) { push @s, "$k => $v"; }
  while ( my ( $k, $v ) = each %{$self->{F}} ) { push @s, "$k => ?" ; }

  return $self->{Sub} . ': ' . join ', ', @s;
}
# -----------------------------------------------------------------------------
sub NoMethod
# -----------------------------------------------------------------------------
{
  my ( $Obj1, $Obj2, $Inv, $Op ) = @_;

  if ( defined $Obj2 || exists $Sub::DeferredPartial::Op::Binary::Ops{$Op} )
  {
    $Obj2 = Sub::DeferredPartial::Op::Nullary->new( $Obj2 ) unless ref $Obj2;
    ( $Obj1, $Obj2 ) = ( $Obj2, $Obj1 ) if $Inv;
    return Sub::DeferredPartial::Op::Binary->new( $Op, $Obj1, $Obj2 );
  }
  return Sub::DeferredPartial::Op::Unary->new( $Op, $Obj1 );
}
# -----------------------------------------------------------------------------
sub Defer
# -----------------------------------------------------------------------------
{
  my $Sub = shift;

  return __PACKAGE__->new( $Sub, Sub::DeferredPartial::Attributes->Hash( $Sub ) );
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

Sub::DeferredPartial - Deferred evaluation / partial application.

=head1 SYNOPSIS

  use Sub::DeferredPartial 'def';

  $S = def sub : P1 P2 P3 { %_=@_; join '', @_{qw(P1 P2 P3)} };

  print $S->( P1 => 1, P2 => 2, P3 => 3 )->(); # 123

  $A = $S->( P3 => 1 );  # partial application
  $B = $S->( P3 => 2 );

  $C = $A + $B;    # deferred evaluation

  $D = $C->( P2 => 3 );
  $E = $D->( P1 => 4 );

  print $E->();    # force evaluation: 863

  $F = $E - $D;

  $G = $F->( P1 => 0 ) / 2;

  print $G->();    # 400
  print $G;        # ( ( CODE(0x15e3818): P1 => 4, P2 => 3, P3 => 1 + CODE ...

  $F->();          # Error: Free parameter : P1
  $A->( P3 => 7 ); # Error: Bound parameter: P3
  $A->( P4 => 7 ); # Error: Wrong parameter: P4

=head1 DESCRIPTION

An instance of this class behaves like a sub (or, more precisely: subroutine
reference), but it supports partial application and the evaluation of
operators applied to such function objects is deferred too.
That means, evaluation has to be forced explicitly (which makes it easier to
add introspection capabilities).

Objects that represent deferred (delayed, suspended) expressions are known
as suspensions or thunks in various programming circles.
Don't confuse with the same terms in the context of threads!

When you use this module, you can specify the name of a subroutine:

  use Sub::DeferredPartial 'def';

or accept the default C<'defer'>:

  use Sub::DeferredPartial;

This subroutine will be imported into your current package and helps you to
create an instance of C<Sub::DeferredPartial>:

  $S = defer sub : P1 P2 { "@_" };

Please note that subroutine attributes are used to declare parameter names.
Now, C<$S> is an instance of C<Sub::DeferredPartial>:

  print ref $S;  # Sub::DeferredPartial

and knows about the subroutine reference and its parameters:

  print $S;  # CODE(0x15e3830): P1 => ?, P2 => ?

Rudimentary introspection capabilities are available through stringification.
The question marks indicate that all parameters are free (unbound).

Parameters are passed as flattened hash to emulate named parameters:

  $T = $S->( P1 => 1, P2 => 2 );

This time, a new suspensions is created where all parameters are bound:

  print $T;  # CODE(0x15e3830): P1 => 1, P2 => 2

Although all parameters are bound, the evaluation of the function is deferred
and has to be forced explicitly:

  print $T->();  # P1 1 P2 2

Up to this point, quite the same could be achieved with ordinary subroutines.
Indeed, every time we define a function (i.e. create an abstraction), the
evaluation of its body is deferred in some way.
However, every application would force the evaluation of the body.
And because Perl does not encourage currying, it would be tedious to write
a closure returning function every time we need to support partial
application.

If you supply only some of the allowed arguments, a new suspension is
created with a mix of free and bound parameters:

  $A = $S->( P2 => 2 );

Parameter P1 is still free, whereas P2 is bound:

  print $A;  # CODE(0x15e3830): P2 => 2, P1 => ?

If you merely need currying, you may consider modules like
L<Sub::Curry|Sub::Curry>,
L<Attribute::Curried|Attribute::Curried> or
L<Perl6::Currying|Perl6::Currying>.

However, this module goes further: The application of operators to
suspensions:

  $C = $A cmp $S->( P1 => 1 );

creates yet another (kind of) suspension:

  print ref $C;  # Sub::DeferredPartial::Op::Binary

Depending on the operator - binary, unary or nullary (i.e. constants) -
different subclasses are used. But that shouldn’t bother you too much.
Assignment operators (mutators) are not supported.
Our poor man's reflection yields:

  print $C;  # ( CODE(...): P2 => 2, P1 => ? cmp CODE(...): P1 => 1, P2 => ? )

A suspended binary operator expects the union of the free parameters of
its operands:

  print map $C->( P1 => 1 )->( P2 => $_ )->(), 1..3;  # 10-1

The deferred evaluation strategy allows to write down expressions in
a natural way - without the need for a wrapper function.
This is the chief difference to the C<*::Curry> modules mentioned above.
Partial application aside, what comes closest is the
L<Symbolic calculator example|overload/"Symbolic calculator">
in the C<overload> module.

=head1 DIAGNOSTICS

=over 1

=item Free parameter ...

  $A->();          # Free parameter: P1

You cannot force evaluation until all parameters are bound.

=item Bound parameter ...

  $A->( P2 => 7 ); # Bound parameter: P2

You cannot bind a parameter that is already bound.

=item Wrong parameter ...

  $A->( P3 => 7 ); # Wrong parameter: P3

You cannot bind a parameter that was not declared.

=back

=head1 TODO

=over

=item Lazy evaluation

Memoization is a common optimization strategy in this context.

=item Conditional operator

An I<if-then-else> or I<case> expression may be useful.

=item Introspection capabilities

Current introspection capabilities (stringification) are quite inflexible
and poking into the internals isn't state of the art ...

=back

=head1 ACKNOWLEDGMENT

Many thanks to Gottlob Frege, Moses SchE<ouml>nfinkel and Haskell Curry
for laying the groundwork.

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Sub::Curry>, L<Attribute::Curried>, L<Perl6::Currying>, L<overload>.

=cut
