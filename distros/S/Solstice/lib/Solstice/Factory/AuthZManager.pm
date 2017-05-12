package Solstice::Factory::AuthZManager;

=head1 NAME

Solstice::Factory::AuthZManager

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Factory);

use Solstice::List;
use Solstice::Factory::AuthZ::Role;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item createByIDs(\@list)

=cut

sub createByIDs {
    my $self = shift;
    my $ids  = shift;
    my $list = Solstice::List->new();
    
    return $list unless @$ids;

    my $placeholder = join(',', map {'?'} @$ids);

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery("SELECT role_id, group_id, object_auth_id FROM $db_name.RoleImplementations 
                    WHERE object_auth_id IN ($placeholder)", @$ids);
    my $manager_hash;
    my $role_array;
    my $group_array;

    while(my $data = $db->fetchRow()){
        push @{$manager_hash->{$data->{'object_auth_id'}}}, $data;
        push @$role_array, $data->{'role_id'};
        push @$group_array, $data->{'group_id'};
    }

    my $roles = Solstice::Factory::AuthZ::Role->new()->createHashByIDs($role_array);
    my $groups = Solstice::Factory::Group->new()->createHashByIDs($group_array);
    foreach (@$ids){
        my $object_auth_id = $_;

        my $role_information = ($object_auth_id) ? $manager_hash->{$_}: [];
        foreach my $role (@$role_information){
            $role->{'role'} = $roles->{$role->{'role_id'}};
            $role->{'group'} = $groups->{$role->{'group_id'}};
        }
        my $init_hash = { id    => $object_auth_id,
                            roles => $role_information,
                        };
        $list->add(Solstice::AuthZManager->new($init_hash));
    }
    return $list;
}


1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 597 $

=head1 SEE ALSO

L<Solstice::List|Solstice::List>.

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
