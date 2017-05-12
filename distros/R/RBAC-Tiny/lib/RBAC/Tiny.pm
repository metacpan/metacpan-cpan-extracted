use strict;
use warnings;
# ABSTRACT: Tiny Role-Based Access Control (RBAC) implementation
package RBAC::Tiny;
$RBAC::Tiny::VERSION = '0.003';
use Carp;
use List::Util;

sub new {
    my ( $class, %args ) = @_;
    my $raw_roles = $args{'roles'}
        or croak "'roles' attribute required";

    return bless { raw_roles => $raw_roles }, $class;
}

sub role {
    my ( $self, $role, $cache ) = @_;
    $cache ||= {};
    return $self->{'role'}{$role} ||= $self->_build_role( $role, $cache );
}

sub _build_role {
    my ( $self, $role, $cache ) = @_;
    my $raw = $self->{'raw_roles'}{$role}
        or croak "No data provided for role '$role'";

    $cache->{$role}
        and croak("Circular dependency detected in '$role' and '$cache->{$role}'");

    my @cans;
    # add all cans from parents, recursively
    foreach my $from ( @{ $raw->{'all_from'} || [] } ) {
        $self->{'raw_roles'}{$from}
            or croak("Role '$from' does not exist but used by '$role'");

        $cache->{$role} = $from;
        my $role = $self->role($from, $cache);
        push @cans, @{ $role->{'can'} || [] };
    }

    # add our own cans
    push @cans, @{ $raw->{'can'} || [] };

    my %can_cache;
    my %except = map +( $_ => 1 ), @{ $raw->{'except'} || [] };
    return {
        can => [
            grep +(
                !$except{$_} and !$can_cache{$_}++
            ), @cans
        ],
    };
}

sub can_role {
    my ( $self, $role, $permission ) = @_;
    return List::Util::first {
        $_ eq $permission
    } @{ $self->role($role)->{'can'} };
}

sub roles {
    my $self = shift;
    return $self->{'roles'} ||= +{
        map +( $_ => $self->role($_) ), keys %{ $self->{'raw_roles'} }
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RBAC::Tiny - Tiny Role-Based Access Control (RBAC) implementation

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $rbac = RBAC::Tiny->new(
        roles => {
            author => {
                can => [ qw<read write publish> ],
            },

            limited_author => {
                all_from => ['author'],
                except   => ['publish'],
            },

            admin => {
                all_from => ['author'],
                can      => ['create_users'],
            },
        },
    );

    $rbac->can_role( author         => 'publish' );      # true
    $rbac->can_role( author         => 'create_users' ); # false
    $rbac->can_role( admin          => 'write' );        # true
    $rbac->can_role( limited_author => 'publish' );      # false
    $rbac->can_role( limited_author => 'create_users' ); # false
    $rbac->can_role( author         => 'create_users' ); # false

=head1 DESCRIPTION

This module implements a tiny simple implementation of Role-Based
Access Control, allowing you to specify roles and what each can
do.

Each role has three optional parameters:

=over 4

=item * all_from

Will gather all the permissions from a list of roles.

=item * can

Add permissions for a role. Will add to permissions provided by
C<all_from>.

=item * except

Remove permissions from a role. Will remove permissions provided
by either C<all_from> or C<except>.

=back

=head1 ATTRIBUTES

=head2 roles

    my $roles = $rbac->roles;

Retrieves all the role definitions.

=head1 METHODS

=head2 new

Create a new object. See synopsis.

=head2 role

    my $role = $rbac->role('author');

Retrieves the role definition.

=head2 can_role

    if ( $rbac->can_role( author => 'write' ) ) {
        ...
    }

Checks whether a role has a certain permission.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Andre Walker <andre@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
