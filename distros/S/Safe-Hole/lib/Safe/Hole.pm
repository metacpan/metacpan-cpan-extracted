# Safe::Hole - make a hole to the original main compartment in the Safe compartment
# Copyright 1999-2001, Sey Nakajima, All rights reserved.
# This program is free software under the GPL.
package Safe::Hole;

require 5.005;
use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '0.14';

bootstrap Safe::Hole $VERSION;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {}, $class;
    $args = { ROOT => $args || 'main' } unless ref $args eq 'HASH';
    if ( $args->{ROOT} ) {
        $self->{PACKAGE} = $args->{ROOT};
        no strict 'refs';
        $self->{STASH} = \%{"$args->{ROOT}::"};
    }
    else {
        $self->{INC}     = [ \%INC, \@INC ];
        $self->{OPMASK}  = _get_current_opmask();
        $self->{PACKAGE} = 'main';
        $self->{STASH}   = \%main::;
    }
    $self;
}

sub call {
    my $self    = shift;
    my $coderef = shift;
    my @args    = @_;

    # _hole_call_sv() does not seem to like being ripped off the stack
    # so we need some fancy footwork to catch and re-throw the error

    my ( @r, $did_not_die );
    my $wantarray = wantarray;

    local (*INC), do {
        *INC = $_ for @{ $self->{INC} };
    } if $self->{INC};

    # Safe::Hole::User contains nothing but is a placeholder so that
    # things that are called via Safe::Hole can Carp::croak properly.

    package Safe::Hole::User;    # Package name on a different line to keep it from being indexed

    my $inner_call = sub {
        eval {
            @_ = @args;
            if ($wantarray) {
                @r = &$coderef;
            }
            else {
                @r = scalar &$coderef;
            }
            $did_not_die = 1;
        };
    };

    Safe::Hole::_hole_call_sv( $self->{STASH}, ${ $self->{OPMASK} || \undef }, $inner_call );

    die $@ unless $did_not_die;
    return wantarray ? @r : $r[0];
}

sub root {
    my $self = shift;
    $self->{PACKAGE};
}

sub wrap {
    my ( $self, $ref, $cpt, $name ) = @_;
    my ( $result, $typechar, $word );
    no strict 'refs';
    if ( $cpt && $name ) {
        croak "Safe object required" unless ref($cpt) eq 'Safe';
        if ( $name =~ /^(\W)(\w+(::\w+)*)$/ ) {
            ( $typechar, $word ) = ( $1, $2 );
        }
        else {
            croak "'$name' not a valid name";
        }
    }
    my $type = ref $ref;
    if ( $type eq '' ) {
        croak "reference required";
    }
    elsif ( $type eq 'CODE' ) {
        $result = sub { $self->call( $ref, @_ ); };
        if ( $typechar eq '&' ) {
            *{ $cpt->root() . "::$word" } = $result;
        }
        elsif ($typechar) {
            croak "'$name' type mismatch with $type";
        }
    }
    elsif ( %{ $type . '::' } ) {
        my $wrapclass = ref($self) . '::' . $self->root() . '::' . $type;
        *{ $wrapclass . '::AUTOLOAD' } = sub {
            $self->call(
                sub {
                    no strict;
                    my $self = shift;
                    return if $AUTOLOAD =~ /::DESTROY$/;
                    my $name = $AUTOLOAD;
                    $name =~ s/.*://;
                    $self->{OBJ}->$name(@_);
                },
                @_
            );
          }
          unless defined &{ $wrapclass . '::AUTOLOAD' };
        $result = bless { OBJ => $ref }, $wrapclass;
        if ( $typechar eq '$' ) {
            ${ $cpt->varglob($word) } = $result;
        }
        elsif ($typechar) {
            croak "'$name' type mismatch with object (must be scalar)";
        }
    }
    else {
        croak "type '$type' is not supported";
    }
    $result;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Safe::Hole - make a hole to the original main compartment in the Safe compartment

=head1 SYNOPSIS

  use Safe;
  use Safe::Hole;
  $cpt = new Safe;
  $hole = new Safe::Hole {};
  sub test { Test->test; }
  $Testobj = new Test;
  # $cpt->share('&test');  # alternate as next line
  $hole->wrap(\&test, $cpt, '&test');
  # ${$cpt->varglob('Testobj')} = $Testobj;  # alternate as next line
  $hole->wrap($Testobj, $cpt, '$Testobj');
  $cpt->reval('test; $Testobj->test;'); 
  print $@ if $@;
  package Test;
  sub new { bless {},shift(); }
  sub test { my $self = shift; $self->test2; }
  sub test2 { print "Test->test2 called\n"; }

=head1 DESCRIPTION

  We can call outside defined subroutines from the Safe compartment
using share(), or can call methods through the object that is copied
into the Safe compartment using varglob(). But that subroutines or
methods are executed in the Safe compartment too, so they cannot call
another subroutines that are dinamically qualified with the package
name such as class methods nor can they compile code that uses opcodes
that are forbidden within the compartment.

  Through Safe::Hole, we can execute outside defined subroutines in the 
original main compartment from the Safe compartment. 

  Note that if a subroutine called through Safe::Hole::call does a
Carp::croak() it will report the error as having occured within
Safe::Hole.  This can be avoided by including Safe::Hole::User in the
@ISA for the package containing the subroutine.

=head2 Methods

=over 4

=item new [NAMESPACE]

Class method. Backward compatible constructor.
  NAMESPACE is the alternate root namespace that makes the compartment
in which call() method execute the subroutine.  Default of NAMESPACE
means the current 'main'. This emulates the behaviour of
Safe-Hole-0.08 and earlier.

=item new \%arguments

Class method. Constructor. 
  The constructor is called with a hash reference providing the
constructor arguments.  The argument ROOT specifies the alternate root
namespace for the object.  If the ROOT argument is not specified then
Safe::Hole object will attempt restore as much as it can of the
environment in which it was constrtucted.  This includes the opcode
mask, C<%INC> and C<@INC>.  If a root namespace is specified then it
would not make sense to restore the %INC and @INC from main:: so this
is not done.  Also if a root namespace is given the opcode mask is not
restored either.

=item call $coderef [,@args]

Object method. 
  Call the subroutine refered by $coderef in the compartment that is
specified with constructor new. @args are passed as the arguments to
the called $coderef.  Note that the arguments are not currently passed
by reference although this may change in a future version.

=item wrap $ref [,$cpt ,$name]

Object method. 
  If $ref is a code reference, this method returns the anonymous 
subroutine reference that calls $ref using call() method of Safe::Hole (see 
above). 
  If $ref is a class object, this method makes a wrapper class of that object 
and returns a new object of the wrapper class. Through the wrapper class, 
all original class methods called using call() method of Safe::Hole.
  If $cpt as Safe object and $name as subroutine or scalar name specified, 
this method works like share() method of Safe. When $ref is a code reference
$name must like '&subroutine'. When $ref is a object $name must like '$var'.
  Name $name may not be same as referent of $ref. For example:
  $hole->wrap(\&foo, $cpt, '&bar');
  $hole->wrap(sub{...}, $cpt, '&foo');
  $hole->wrap($objfoo, $cpt, '$objbar');

=item root

Object method.
Return the namespace that is specified with constructor new().
If no namespace was then root() returns 'main'.

=back

=head2 Warning

You MUST NOT share the Safe::Hole object with the Safe compartment. If you do it
the Safe compartment is NOT safe.

This module provides a means to go from a state where an opcode is
denied back to a state where it is not.  Reasonable care has been
taken to ensure that programs cannot simply manipulate the internals
to the Safe::Hole object to reduce the opmask in effect.  However there
may still be a way that the authors have not considered.  In
particular it relies on the fact that a Perl program cannot change
stuff inside the magic on a Perl variable.  If you install a module
that allows a Perl program to fiddle inside the magic then this
assuption breaks down.  One would hope that any system that was
running un-trusted code would not have such a module installed.

=head1 AUTHORS

Sey Nakajima <nakajima@netstock.co.jp> (Initial version)

Brian McCauley <nobull@cpan.org> (Maintenance)

Todd Rinaldo <toddr@cpan.org> (Maintenance)

=head1 SEE ALSO

Safe(3).
