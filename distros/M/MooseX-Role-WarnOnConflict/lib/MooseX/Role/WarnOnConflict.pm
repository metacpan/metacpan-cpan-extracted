package MooseX::Role::WarnOnConflict;

# ABSTRACT: Warn if classes override role methods without excluding them

use warnings;
use strict;

our $VERSION = '0.01';

use MooseX::Meta::Role::WarnOnConflict;
use Moose::Role;
use Moose::Exporter;
Moose::Exporter->setup_import_methods( also => 'Moose::Role' );

sub init_meta {
    my ( $class, %opt ) = @_;
    return Moose::Role->init_meta(    ##
        %opt,                         ##
        metaclass => 'MooseX::Meta::Role::WarnOnConflict'
    );
}

package    # Hide from PAUSE
  MooseX::Meta::Role::Application::ToClass::WarnOnConflig;
use Moose;
use Carp 'carp';
our @CARP_NOT = (__PACKAGE__);
extends 'Moose::Meta::Role::Application::ToClass';

sub apply_methods {
    my ( $self, $role, $class ) = @_;
    my @implicitly_overridden;

    METHOD: foreach my $method_name ( $role->get_method_list ) {
        next METHOD if 'meta' eq $method_name;    # Moose auto-exports this
        unless ( $self->is_method_excluded($method_name) ) {

            # it if it has one already
            if (
                $class->has_method($method_name)
                &&

                # and if they are not the same thing ...
                $class->get_method($method_name)->body !=
                $role->get_method($method_name)->body
              )
            {
                push @implicitly_overridden => $method_name;
                next;
            }
            else {
                # add method to the required methods
                $role->add_required_methods($method_name);

                # add it, although it could be overridden
                $class->add_method( $method_name,
                    $role->get_method($method_name) );
            }
        }

        if ( $self->is_method_aliased($method_name) ) {
            my $aliased_method_name = $self->get_method_aliases->{$method_name};

            # it if it has one already
            if (
                $class->has_method($aliased_method_name)
                &&

                # and if they are not the same thing ...
                $class->get_method($aliased_method_name)->body !=
                $role->get_method($method_name)->body
              )
            {
                my $class_name = $class->name;
                my $role_name  = $role->name;
                carp(
"$class_name should not alias $role_name '$method_name' to '$aliased_method_name' if a local method of the same name exists"
                );
            }
            $class->add_method( $aliased_method_name,
                $role->get_method($method_name) );
        }
    }

    if (@implicitly_overridden) {
        my $s = @implicitly_overridden > 1 ? "s" : "";

        my $class_name = $class->name;
        my $role_name  = $role->name;
        my $methods    = join ', ' => @implicitly_overridden;

        # we use \n because we have no hope of guessing the right stack frame,
        # it's almost certainly never going to be the one above us
        carp(<<"        END_ERROR");
The class $class_name has implicitly overridden the method$s ($methods) from
role $role_name. If this is intentional, please exclude the method$s from
composition to silence this warning (see Moose::Cookbook::Roles::Recipe2)
        END_ERROR
    }

    # we must reset the cache here since
    # we are just aliasing methods, otherwise
    # the modifiers go wonky.
    $class->reset_package_cache_flag;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::WarnOnConflict - Warn if classes override role methods without excluding them

=head1 VERSION

version 0.01

=head1 SYNOPSIS

This code will warn at composition time:

    {
        package My::Role;
        use MooseX::Role::WarnOnConflict;
        sub conflict {}
    }
    {
        package My::Class;
        use Moose;
        with 'My::Role';
        sub conflict {}
    }

With an error message similar to the following:

    The class My::Class has implicitly overridden the method (conflict) from
    role My::Role ...

To resolve this, explicitly exclude the 'conflict' method:

    {
        package My::Class;
        use Moose;
        with 'My::Role' => { -excludes => [ 'conflict' ] };
        sub conflict {}
    }

Aliasing a role method to an existing method will also warn:

    {
        package My::Class;
        use Moose;
        with 'My::Role' => {
            -excludes => ['conflict'],
            -alias    => { conflict => 'another_method' },
        };
        sub conflict       { }
        sub another_method { }
    }

=head1 DESCRIPTION

When using L<Moose::Role>, a class which provides a method a role provides
will silently override that method.  This can cause strange, hard-to-debug
errors when the role's methods are not called.  Simply use
C<MooseX::Role::WarnOnConflict> instead of C<Moose::Role> and overriding a
role's method becomes a composition-time warning.  See the synopsis for a
resolution.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
