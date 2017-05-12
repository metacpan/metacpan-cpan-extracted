package Perl6::Roles;

use 5.6.0;

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util qw( blessed refaddr );
use List::MoreUtils qw( uniq );

my %does; # {class}{role} = 1
my %from; # {class}{method} = role

sub _get_all_roles {
    my $r = shift;

    my @roles = ( $r );
    push @roles, map { _get_all_roles($_) } keys %{$does{$r} ||= {}};
    return uniq( @roles );
}

sub apply {
    my ($role, $class) = @_;

    if ( my $old_class = blessed($class) ) {
        no strict 'refs';

        $class = "${old_class}::" . refaddr($class);
        push @{ "${class}::ISA" }, $old_class;

        # This requires direct access into @_ in order to affect the parameter,
        # not just the copy of the parameter.
        bless $_[1], $class;
    }

    my @methods;
    foreach my $r ( _get_all_roles( $role ) ) {
        no strict 'refs';

        # A role is valid if-and-only-if the following conditions hold:
        # 1) It is a direct descendent of __PACKAGE__
        # 2) Its only ancestor is __PACKAGE__
        my @isa = @{ "${r}::ISA" };
        if ( @isa > 1 || $isa[0] ne __PACKAGE__ ) {
            die "$r is an invalid role because it has inheritance other than "
              . __PACKAGE__ . "\n";
        }

        # No matter what, mark $class as "does $role"
        $does{ $class }{ $r } = 1;

        push @methods, map { [ $r, $_ ] } grep { 
            *{"${r}::${_}"}{CODE} 
        } keys %{"${r}::"};
    }

    # Only compose methods in if the $class isn't, itself, a role.
    # Roles don't flatten until they are composed into a class.
    if ( !$class->isa( __PACKAGE__ ) ) {
        METHOD:
        foreach my $item (@methods) {
            my ($r, $method) = @$item;
            no strict 'refs';

            # Don't override a method that already exists, but we need to
            # check for conflicts.
            if (*{"${class}::${method}"}{CODE}) {

                # If the method was installed by another role, die in order to
                # force the class owner to resolve the conflict.
                my $conflict = $from{ $class }{ $method };
                if ( $conflict && $conflict ne $r ) {
                    die "Attempt to re-compose '$method' into '$class'\n"
                      . "\tConflicting roles: '$conflict' <-> '$r'\n";
                }

                # Otherwise, we skip this method because the class owner has
                # already (apparently) resolved the conflict.
                next METHOD;
            }

            # Install the method ...
            *{"${class}::${method}"} = \&{"${r}::${method}"};

            # ... and record which role provides this method.
            $from{ $class }{ $method } = $r;
        }
    }

    return 1;
}

sub _check_isa {
    my ($class, $role) = @_;

    no strict 'refs';
    for my $parent ( @{ "${class}::ISA" } ) {
        return 1 if $parent->does( $role ) or _check_isa( $parent, $role );
    }

    return;
}

*UNIVERSAL::does = sub {
    my ($proto, $role) = @_;

    my $class = blessed $proto;
    $class = $proto unless $class;

    return 1 if $class eq $role;
    return 1 if $does{ $class }{ $role };

    return _check_isa( $class, $role );
};

1;
__END__

=head1 NAME

Perl6::Role - Perl6 roles in Perl5

=head1 SYNOPSIS

  package Some::Role;
  
  # to make the package a role, 
  # just inherit from Perl6::Roles
  use base 'Perl6::Roles'; 

  sub foo { ... }
  sub foobar { ... }

  package Some::Other::Role;

  use base 'Perl6::Roles';

  sub bar { ... }

  package Your::Class;

  use Some::Role;
  Some::Role->apply( __PACKAGE__ );
  # or ...
  Some::Role->apply( 'Some::Class' ); 

  sub new { ... }
  sub foobar { ... }
  sub bar { ... }

  package main;

  my $object = Your::Class->new;
  $object->foo(); # This calls Some::Role::foo()
  $object->bar(); # This calls Your::Class::bar()
  $object->foobar(); # This calls Your::Class::foobar()
  
  if ( Your::Class->does( 'Some::Role' ) ) {
      # This will evaluate as true
  }

  if ( $object->does( 'Some::Role' ) ) {
      # This will evaluate as true
  }

  Some::Other::Role->apply( $object );

  if ( Your::Class->does( 'Some::Other::Role' ) ) {
      # This will evaluate as false
  }

  if ( $object->does( 'Some::Other::Role' ) ) {
      # This will evaluate as true
  }

=head1 DESCRIPTION

This is an implementation of current state of Perl6 roles in Perl5. It draws 
very heavily from both the L<Class::Role> and L<Class::Roles> modules, but 
is backwards compatible with neither of them. 

=head1 ROLES

=head2 What is a Role?

Roles are a form of B<behavior> reuse, and can be thought of as a collection 
of methods unassociated with a particular class. Roles are composed into 
classes, at which point the methods in the role are I<flattened> into that 
particular class. 

A valid role is one that inherits directly from Perl6::Roles and does B<not>
inherit from anything else. Other than that, it is just a package with 
methods inside.

=head2 Is attribute composition supported? 

Since Perl (5) provides no consistent way to handle instance attributes, 
it is difficult to code this behavior in a generic way. That is not to say
it is not possible to do this, especially given some kind of consistent 
class/instance structure. However, this is left as an exercise for the reader.

=head1 METHODS

=head2 C<apply( $class|$object )>

If a $class, this will apply the role (which is the invocant) to the given
class. It will add all the methods within the role that the class doesn't
already have and mark the class as 'does' the role.

If an $object, this will create a new class that inherits from the original
class, apply the role to that new class, and rebless the object into that new
class.

=head2 C<does( $role )>

This method is not actually contained within Perl6::Roles. It is installed in
UNIVERSAL, which is the package that all objects automagically inherit from.
This allows the syntax C<$some_random_object-E<gt>does( 'Some::Role' );>.

This method will return true if the given class or object 'does' the given
role and false otherwise.

B<Note:> A class does itself and all its parents. An object does its class and
all of its parent classes.

=head1 CODE COVERAGE

We use L<Devel::Cover> to test the code coverage of our tests. Below is the
L<Devel::Cover> report on this module's test suite.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  /Perl6/Roles.pm               100.0  100.0   90.9  100.0  100.0  100.0   99.2
  Total                         100.0  100.0   90.9  100.0  100.0  100.0   99.2
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 ACKNOWLEDGEMENTS

This code is based very heavily upon both L<Class::Role> (written by Luke
Palmer) and L<Class::Roles> (written by chromatic).

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
