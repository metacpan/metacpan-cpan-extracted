package RTx::RightsMatrix;

use strict;
use Data::Dumper;
use Storable;
use RTx::RightsMatrix::Util;
use RTx::RightsMatrix::RolePrincipal;

=head1 NAME

RTx::RightsMatrix - Bulk editing GUI for RT rights

=head1 SYNOPSIS

Point, click, drool

=head2 Documentation

Patches are wellcome.

=head2 Todo

=head2 Repository

You can find repository of this project at
L<svn://svn.chaka.net/RTx-RightsMatrix>

=cut

our $VERSION = '0.03.00';

{
    no warnings qw(redefine);

    package RT::System;
    sub Name { return 'System'; }
}

# Teach RT how to ask if a Principal has a right assigned directly as opposed
# to being ingerited from a group or role.
{
    no warnings qw(redefine);

    package RT::Principal;

    sub _HasDirectRight {
        my $self = shift;

        my %args = @_;

        my $cu = $self->CurrentUser;

        my $PrincipalType = 'Group';
        
        # if we are calling this on a Role, set the PrincipalType to that role
        if ($self->IsGroup) {
            # Groups.Type to ACL.Principal
            my @roles = qw( AdminCc Cc Admin Owner Requestor );
        
            $PrincipalType = $self->Object->Type if grep { $self->Object->Type eq $_ } @roles;

        }

        my $acl = RT::ACL->new($cu);
        $acl->Limit( FIELD => 'RightName', VALUE => $args{Right} );
        $acl->Limit( FIELD => 'PrincipalType', VALUE => $PrincipalType );
        $acl->Limit( FIELD => 'ObjectType', VALUE => ref($args{Object}) );
        $acl->Limit( FIELD => 'ObjectId', VALUE => $args{Object}->id );
        #$acl->Limit( FIELD => 'ObjectId', VALUE => 0, ENTRYAGGREGATOR => 'OR' ) if ref($args{Object}) =~ /RT::System/;

        if ($self->IsUser) {
            my $groups = RT::Groups->new($cu);
            $groups->Limit(FIELD => 'Instance', VALUE => $self->id);
            $groups->Limit(FIELD => 'Domain', VALUE => 'ACLEquivalence');
            my $equiv_group = $groups->First;

            $acl->Limit( FIELD => 'PrincipalId', VALUE => $equiv_group->id );
        }
        elsif ($self->IsGroup) {
            $acl->Limit( FIELD => 'PrincipalId', VALUE => $self->id );
        }
        return $acl->Count;
    }

    sub __RolesForObject {
        my $self = shift;
        my $type = shift;
        my $id = shift;
    
        #unless ($id) {
            #$id = '0';
        #}
        if ( !$id or $type =~ /RTx?.*::System$/) {
            $id = 0;
        }

        # This should never be true.
        unless ($id =~ /^\d+$/) {
             $RT::Logger->crit("RT::Prinicipal::_RolesForObject called with type $type and a non-integer id: '$id'");
             $id = "'$id'";
        }

        my $clause = "(Groups.Domain = '".$type."-Role' AND Groups.Instance = $id) ";

        return($clause);
     }
 
}

=head1 AUTHOR

Todd Chapman, C<< <todd@chaka.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rtx-rightsmatrix@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RTx-RightsMatrix>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Todd Chapman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of RTx::RightsMatrix
