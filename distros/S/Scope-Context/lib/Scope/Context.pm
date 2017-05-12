package Scope::Context;

use 5.006;

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use Scope::Upper 0.21 ();

=head1 NAME

Scope::Context - Object-oriented interface for inspecting or acting upon upper scope frames.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Scope::Context;

    for (1 .. 5) {
     sub {
      eval {
       # Create Scope::Context objects for different upper frames :
       my ($block, $eval, $sub, $loop);
       {
        $block = Scope::Context->new;
        $eval  = $block->eval;   # == $block->up
        $sub   = $block->sub;    # == $block->up(2)
        $loop  = $sub->up;       # == $block->up(3)
       }

       eval {
        # This throws an exception, since $block has expired :
        $block->localize('$x' => 1);
       };

       # This will print "hello" when the current eval block ends :
       $eval->reap(sub { print "hello\n" });

       # Ignore warnings just for the loop body :
       $loop->localize_elem('%SIG', __WARN__ => sub { });

       # Execute the callback as if it ran in place of the sub :
       my @values = $sub->uplevel(sub {
        return @_, 2;
       }, 1);
       # @values now contains (1, 2).

       # Immediately return (1, 2, 3) from the sub, bypassing the eval :
       $sub->unwind(@values, 3);

       # Not reached.
      }

      # Not reached.
     }->();

     # unwind() returns here. "hello\n" was printed, and now warnings are
     # ignored.
    }

    # $SIG{__WARN__} has been restored to its original value, warnings are no
    # longer ignored.

=head1 DESCRIPTION

This class provides an object-oriented interface to L<Scope::Upper>'s functionalities.
A L<Scope::Context> object represents a currently active dynamic scope (or context), and encapsulates the corresponding L<Scope::Upper>-compatible context identifier.
All of L<Scope::Upper>'s functions are then made available as methods.
This gives you a prettier and safer interface when you are not reaching for extreme performance, but rest assured that the overhead of this module is minimal anyway.

The L<Scope::Context> methods actually do more than their subroutine counterparts from L<Scope::Upper> : before each call, the target context will be checked to ensure it is still active (which means that it is still present in the current call stack), and an exception will be thrown if you attempt to act on a context that has already expired.
This means that :

    my $cxt;
    {
     $cxt = Scope::Context->new;
    }
    $cxt->reap(sub { print "hello\n });

will croak when L</reap> is called.

=head1 METHODS

=head2 C<new>

    my $cxt = Scope::Context->new;
    my $cxt = Scope::Context->new($scope_upper_cxt);

Creates a new immutable L<Scope::Context> object from the L<Scope::Upper>-comptabile context identifier C<$context>.
If omitted, C<$context> defaults to the current context.

=cut

sub new {
 my ($self, $cxt) = @_;

 my $class = Scalar::Util::blessed($self);
 unless (defined $class) {
  $class = defined $self ? $self : __PACKAGE__;
 }

 $cxt = Scope::Upper::UP() unless defined $cxt;

 bless {
  cxt => $cxt,
  uid => Scope::Upper::uid($cxt),
 }, $class;
}

=head2 C<here>

A synonym for L</new>.

=cut

BEGIN {
 *here = \&new;
}

sub _croak {
 shift;
 require Carp;
 Carp::croak(@_);
}

=head2 C<cxt>

    my $scope_upper_cxt = $cxt->cxt;

Read-only accessor to the L<Scope::Upper> context identifier associated with the invocant.

=head2 C<uid>

    my $uid = $cxt->uid;

Read-only accessor to the L<Scope::Upper> unique identifier representing the L<Scope::Upper> context associated with the invocant.

=cut

BEGIN {
 local $@;
 eval "sub $_ { \$_[0]->{$_} }; 1" or die $@ for qw<cxt uid>;
}

=pod

This class also overloads the C<==> operator, which will return true if and only if its two operands are L<Scope::Context> objects that have the same UID.

=cut

use overload (
 '==' => sub {
  my ($left, $right) = @_;

  unless (Scalar::Util::blessed($right) and $right->isa(__PACKAGE__)) {
   $left->_croak('Cannot compare a Scope::Context object with something else');
  }

  $left->uid eq $right->uid;
 },
 fallback => 1,
);

=head2 C<is_valid>

    my $is_valid = $cxt->is_valid;

Returns true if and only if the invocant is still valid (that is, it designates a scope that is higher on the call stack than the current scope).

=cut

sub is_valid { Scope::Upper::validate_uid($_[0]->uid) }

=head2 C<assert_valid>

    $cxt->assert_valid;

Throws an exception if the invocant has expired and is no longer valid.
Returns true otherwise.

=cut

sub assert_valid {
 my $self = shift;

 $self->_croak('Context has expired') unless $self->is_valid;

 1;
}

=head2 C<package>

    $cxt->package;

Returns the namespace in use when the scope denoted by the invocant begins.

=head2 C<file>

    $cxt->file;

Returns the name of the file where the scope denoted by the invocant belongs to.

=head2 C<line>

    $cxt->line;

Returns the line number where the scope denoted by the invocant begins.

=head2 C<sub_name>

    $cxt->sub_name;

Returns the name of the subroutine called for this context, or C<undef> if this is not a subroutine context.

=head2 C<sub_has_args>

    $cxt->sub_has_args;

Returns a boolean indicating whether a new instance of C<@_> was set up for this context, or C<undef> if this is not a subroutine context.

=head2 C<gimme>

    $cxt->gimme;

Returns the context (in the sense of C<perlfunc/wantarray> : C<undef> for void context, C<''> for scalar context, and true for list context) in which the scope denoted by the invocant is executed.

=head2 C<eval_text>

    $cxt->eval_text;

Returns the contents of the string being compiled for this context, or C<undef> if this is not an eval context.

=head2 C<is_require>

    $cxt->is_require;

Returns a boolean indicating whether this eval context was created by C<require>, or C<undef> if this is not an eval context.

=head2 C<hints_bits>

    $cxt->hints_bits;

Returns the value of the lexical hints bit mask (available as C<$^H> at compile time) in use when the scope denoted by the invocant begins.

=head2 C<warnings_bits>

    $cxt->warnings_bits;

Returns the bit string representing the warnings (available as C<${^WARNING_BITS}> at compile time) in use when the scope denoted by the invocant begins.

=head2 C<hints_hash>

    $cxt->hints_hash;

Returns a reference to the lexical hints hash (available as C<%^H> at compile time) in use when the scope denoted by the invocant begins.
This method is available only on perl 5.10 and greater.

=cut

BEGIN {
 my %infos = (
  package       => 0,
  file          => 1,
  line          => 2,
  sub_name      => 3,
  sub_has_args  => 4,
  gimme         => 5,
  eval_text     => 6,
  is_require    => 7,
  hints_bits    => 8,
  warnings_bits => 9,
  (hints_hash   => 10) x ("$]" >= 5.010),
 );

 for my $name (sort { $infos{$a} <=> $infos{$b} } keys %infos) {
  my $idx = $infos{$name};
  local $@;
  eval <<"  TEMPLATE";
   sub $name {
    my \$self = shift;

    \$self->assert_valid;

    my \$info = \$self->{info};
    \$info = \$self->{info} = [ Scope::Upper::context_info(\$self->cxt) ]
                                                                  unless \$info;

    return \$info->[$idx];
   }
  TEMPLATE
  die $@ if $@;
 }
}

=head2 C<want>

    my $want = $cxt->want;

Returns the Perl context (in the sense of C<perlfunc/wantarray>) in which is executed the closest subroutine, eval or format enclosing the scope pointed by the invocant.

=cut

sub want {
 my $self = shift;

 $self->assert_valid;

 Scope::Upper::want_at($self->cxt);
}

=head2 C<up>

    my $up_cxt = $cxt->up;
    my $up_cxt = $cxt->up($frames);
    my $up_cxt = Scope::Context->up;

Returns a new L<Scope::Context> object pointing to the C<$frames>-th upper scope above the scope pointed by the invocant.

This method can also be invoked as a class method, in which case it is equivalent to calling L</up> on a L<Scope::Context> object representing the current context.

If omitted, C<$frames> defaults to C<1>.

    sub {
     {
      {
       my $up = Scope::Context->new->up(2); # == Scope::Context->up(2)
       # $up points two contextes above this one, which is the sub.
      }
     }
    }

=cut

sub up {
 my ($self, $frames) = @_;

 my $cxt;
 if (Scalar::Util::blessed($self)) {
  $self->assert_valid;
  $cxt = $self->cxt;
 } else {
  $cxt = Scope::Upper::UP(Scope::Upper::SUB());
 }

 $frames = 1 unless defined $frames;

 $cxt = Scope::Upper::UP($cxt) for 1 .. $frames;

 $self->new($cxt);
}

=head2 C<sub>

    my $sub_cxt = $cxt->sub;
    my $sub_cxt = $cxt->sub($frames);
    my $sub_cxt = Scope::Context->sub;

Returns a new L<Scope::Context> object pointing to the C<$frames + 1>-th subroutine scope above the scope pointed by the invocant.

This method can also be invoked as a class method, in which case it is equivalent to calling L</sub> on a L<Scope::Context> object for the current context.

If omitted, C<$frames> defaults to C<0>, which results in the closest sub enclosing the scope pointed by the invocant.

    outer();

    sub outer {
     inner();
    }

    sub inner {
     my $sub = Scope::Context->new->sub(1); # == Scope::Context->sub(1)
     # $sub points to the context for the outer() sub.
    }

=cut

sub sub {
 my ($self, $frames) = @_;

 my $cxt;
 if (Scalar::Util::blessed($self)) {
  $self->assert_valid;
  $cxt = $self->cxt;
 } else {
  $cxt = Scope::Upper::UP(Scope::Upper::SUB());
 }

 $frames = 0 unless defined $frames;

 $cxt = Scope::Upper::SUB($cxt);
 $cxt = Scope::Upper::SUB(Scope::Upper::UP($cxt)) for 1 .. $frames;

 $self->new($cxt);
}

=head2 C<eval>

    my $eval_cxt = $cxt->eval;
    my $eval_cxt = $cxt->eval($frames);
    my $eval_cxt = Scope::Context->eval;

Returns a new L<Scope::Context> object pointing to the C<$frames + 1>-th C<eval> scope above the scope pointed by the invocant.

This method can also be invoked as a class method, in which case it is equivalent to calling L</eval> on a L<Scope::Context> object for the current context.

If omitted, C<$frames> defaults to C<0>, which results in the closest eval enclosing the scope pointed by the invocant.

    eval {
     sub {
      my $eval = Scope::Context->new->eval; # == Scope::Context->eval
      # $eval points to the eval context.
     }->()
    }

=cut

sub eval {
 my ($self, $frames) = @_;

 my $cxt;
 if (Scalar::Util::blessed($self)) {
  $self->assert_valid;
  $cxt = $self->cxt;
 } else {
  $cxt = Scope::Upper::UP(Scope::Upper::SUB());
 }

 $frames = 0 unless defined $frames;

 $cxt = Scope::Upper::EVAL($cxt);
 $cxt = Scope::Upper::EVAL(Scope::Upper::UP($cxt)) for 1 .. $frames;

 $self->new($cxt);
}

=head2 C<reap>

    $cxt->reap($code);

Executes C<$code> when the scope pointed by the invocant ends.

See L<Scope::Upper/reap> for details.

=cut

sub reap {
 my ($self, $code) = @_;

 $self->assert_valid;

 &Scope::Upper::reap($code, $self->cxt);
}

=head2 C<localize>

    $cxt->localize($what, $value);

Localizes the variable described by C<$what> to the value C<$value> when the control flow returns to the scope pointed by the invocant, until said scope ends.

See L<Scope::Upper/localize> for details.

=cut

sub localize {
 my ($self, $what, $value) = @_;

 $self->assert_valid;

 Scope::Upper::localize($what, $value, $self->cxt);
}

=head2 C<localize_elem>

    $cxt->localize_elem($what, $key, $value);

Localizes the element C<$key> of the variable C<$what> to the value C<$value> when the control flow returns to the scope pointed by the invocant, until said scope ends.

See L<Scope::Upper/localize_elem> for details.

=cut

sub localize_elem {
 my ($self, $what, $key, $value) = @_;

 $self->assert_valid;

 Scope::Upper::localize_elem($what, $key, $value, $self->cxt);
}

=head2 C<localize_delete>

    $cxt->localize_delete($what, $key);

Deletes the element C<$key> from the variable C<$what> when the control flow returns to the scope pointed by the invocant, and restores it to its original value when said scope ends.

See L<Scope::Upper/localize_delete> for details.

=cut

sub localize_delete {
 my ($self, $what, $key) = @_;

 $self->assert_valid;

 Scope::Upper::localize_delete($what, $key, $self->cxt);
}

=head2 C<unwind>

    $cxt->unwind(@values);

Immediately returns the scalars listed in C<@values> from the closest subroutine enclosing the scope pointed by the invocant.

See L<Scope::Upper/unwind> for details.

=cut

sub unwind {
 my $self = shift;

 $self->assert_valid;

 Scope::Upper::unwind(@_ => $self->cxt);
}

=head2 C<yield>

    $cxt->yield(@values);

Immediately returns the scalars listed in C<@values> from the scope pointed by the invocant, whatever it may be (except a substitution eval context).

See L<Scope::Upper/yield> for details.

=cut

sub yield {
 my $self = shift;

 $self->assert_valid;

 Scope::Upper::yield(@_ => $self->cxt);
}

=head2 C<uplevel>

    my @ret = $cxt->uplevel($code, @args);

Executes the code reference C<$code> with arguments C<@args> in the same setting as the closest subroutine enclosing the scope pointed by the invocant, then returns to the current scope the values returned by C<$code>.

See L<Scope::Upper/uplevel> for details.

=cut

sub uplevel {
 my $self = shift;
 my $code = shift;

 $self->assert_valid;

 &Scope::Upper::uplevel($code => @_ => $self->cxt);
}

=head1 DEPENDENCIES

L<Carp> (core module since perl 5), L<overload> (since 5.2.0), L<Scalar::Util> (since 5.7.3).

L<Scope::Upper> 0.21.

=head1 SEE ALSO

L<Scope::Upper>.

L<Continuation::Escape>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-scope-context at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scope-Context>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scope::Context

=head1 COPYRIGHT & LICENSE

Copyright 2011,2012,2013,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Scope::Context
