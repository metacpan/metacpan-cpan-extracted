package MooseX::Role::Strict;

use warnings;
use strict;

our $VERSION = 0.05;

use MooseX::Meta::Role::Strict;
use Moose::Role;
use Moose::Exporter;
Moose::Exporter->setup_import_methods( also => 'Moose::Role' );

sub init_meta {
    my ( $class, %opt ) = @_;
    return Moose::Role->init_meta(    ##
        %opt,                         ##
        metaclass => 'MooseX::Meta::Role::Strict'
    );
}

package    # Hide from PAUSE
  MooseX::Meta::Role::Application::ToClass::Strict;
use Moose;
extends 'Moose::Meta::Role::Application::ToClass';

sub apply_methods {
    my ( $self, $role, $class ) = @_;
    my @implicitly_overridden;

    foreach my $method_name ( $role->get_method_list ) {
        next if 'meta' eq $method_name; # Moose auto-exports this
        unless ( $self->is_method_excluded($method_name) ) {
            # it if it has one already
            if (
                $class->has_method($method_name) &&
                # and if they are not the same thing ...
                $class->get_method($method_name)->body != $role->get_method($method_name)->body
              )
            {
                push @implicitly_overridden => $method_name;
                next;
            }
            else {

                # add it, although it could be overridden
                $class->add_method( $method_name,
                    $role->get_method($method_name) );
            }
        }

        if ( $self->is_method_aliased($method_name) ) {
            my $aliased_method_name = $self->get_method_aliases->{$method_name};

            # it if it has one already
            if (
                $class->has_method($aliased_method_name) &&
                # and if they are not the same thing ...
                $class->get_method($aliased_method_name)->body != $role->get_method($method_name)->body
              )
            {
                $class->throw_error("Cannot create a method alias if a local method of the same name exists");
            }
            $class->add_method( $aliased_method_name,
                $role->get_method($method_name) );
        }
    }

    if (@implicitly_overridden) {
        my $s = @implicitly_overridden > 1 ? "s" : "";

        my $class_name = $class->name;
        my $role_name  = $role->name;
        my $methods = join ', ' => @implicitly_overridden;
        # we use \n because we have no hope of guessing the right stack frame,
        # it's almost certainly never going to be the one above us
        $class->throw_error(<<"        END_ERROR");
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

=head1 NAME

MooseX::Role::Strict - use strict 'roles'

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This code will fail at composition time:

    {
        package My::Role;
        use MooseX::Role::Strict;
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

To resolve this, explictly exclude the 'conflict' method:

    {
        package My::Class;
        use Moose;
        with 'My::Role' => { -excludes => 'conflict' };
        sub conflict {}
    }

=head1 DESCRIPTION

B<WARNING>:  this is ALPHA code.  More features to be added later.

When using L<Moose::Role>, a class which provides a method a role provides
will silently override that method.  This can cause strange, hard-to-debug
errors when the role's methods are not called.  Simple use
C<MooseX::Role::Strict> instead of C<Moose::Role> and overriding a role's
method becomes a composition-time failure.  See the synopsis for a resolution.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-role-strict at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-Strict>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Strict

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Role-Strict>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Role-Strict>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Strict>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Role-Strict/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 TODO

Add C<-includes> to make things easier:

 with 'Some::Role' => { -includes => 'bar' };

That reverses the sense of '-excludes' in case you're more interested in the
interface than the implementation.  I'm unsure of the syntax for
auto-converting a role to a pure interface.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
