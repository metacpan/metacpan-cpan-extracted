package Solstice::Factory::Group;

=head1 NAME

Solstice::Factory::Group - Has the ability to create group objects.

=head1 SYNOPSIS

my $factory = Solstice::Factory::Group->new();
my $list = $factory->createByIDs(\@group_ids);
my $list = $factory->createByOwner($person);
my $list = $factory->createByMember($person);

=head1 DESCRIPTION

This object has the ability to create groups.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Factory);

use Solstice::Application;
use Solstice::Database;
use Solstice::DateTime;
use Solstice::List;
use Solstice::Group;
use Solstice::Subgroup;

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

    return $list unless defined $ids && scalar @$ids;

    my $select_string = join ',', map { '?' } @$ids;
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    # Aggregate subgroup query
    $db->readQuery("SELECT sig.parent_group_id, sg.*
        FROM $db_name.SubgroupsInGroup AS sig
            JOIN $db_name.Subgroup AS sg USING(subgroup_id)
        WHERE sig.parent_group_id IN ($select_string)
        GROUP BY sg.subgroup_id
        ORDER BY sig.parent_group_id", @$ids);

    my $subgroups = {};
    while (my $data = $db->fetchRow()) {
        my $subgroup = Solstice::Subgroup->new({
            id            => $data->{'subgroup_id'},
            name          => $data->{'name'},
            creation_date => Solstice::DateTime->new($data->{'date_created'}),
            date_modified => Solstice::DateTime->new($data->{'date_modified'}),
            root_group_id => $data->{'parent_group_id'},
        });
        $subgroups->{$data->{'parent_group_id'}}->{$data->{'subgroup_id'}} = $subgroup;
    }

    # Aggregate remote group query
    my $remote_group_factory = Solstice::Factory::Group::Remote->new();
    my $remote_groups = $remote_group_factory->createHashByGroupIDs($ids);

    # Aggregate member group query
    $db->readQuery("SELECT gg.parent_group_id, gg.group_id
        FROM $db_name.GroupsInGroup AS gg
        WHERE gg.parent_group_id IN ($select_string)", @$ids);
   
    my $member_groups = {};
    while (my $data = $db->fetchRow()) {
        my $member_group_ids = $member_groups->{$data->{'parent_group_id'}} || [];
        push @$member_group_ids, $data->{'group_id'};
        $member_groups->{$data->{'parent_group_id'}} = $member_group_ids;
    }
    
    # Aggregate group owner query
    $db->readQuery("SELECT go.*
        FROM $db_name.GroupOwner AS go
        WHERE go.group_id IN ($select_string)", @$ids);

    my @person_ids = ();
    my $owners = {};
    while (my $data = $db->fetchRow()) {
        push @person_ids, $data->{'person_id'};
        $owners->{$data->{'group_id'}}->{$data->{'person_id'}} = undef;
    }

    # Finally, the aggregate group query
    $db->readQuery("SELECT g.*
        FROM $db_name.Groups AS g
        WHERE g.is_visible = 1 AND g.group_id IN ($select_string)
        GROUP BY g.group_id", @$ids);

    my @group_data = ();
    while (my $data = $db->fetchRow()) {
        push @group_data, $data;
        push @person_ids, $data->{'creator_id'};
    }

    my $person_factory = Solstice::Factory::Person->new();
    my $person_lookup = $person_factory->createHashByIDs(\@person_ids); 

    for my $data (@group_data) {
        my $group_owners = $owners->{$data->{'group_id'}};
        for my $person_id (keys %$group_owners) {
            $group_owners->{$person_id} = $person_lookup->{$person_id};
        }

        my $group = Solstice::Group->new({
            id                   => $data->{'group_id'},
            name                 => $data->{'name'},
            description          => $data->{'description'},
            modification_date    => Solstice::DateTime->new($data->{'date_modified'}),
            creation_date        => Solstice::DateTime->new($data->{'date_created'}),
            creation_application => Solstice::Application->new($data->{'application_id'}),
            creator              => $person_lookup->{$data->{'creator_id'}},
            subgroups            => $subgroups->{$data->{'group_id'}} || {},
            remote_groups        => $remote_groups->{$data->{'group_id'}} || {},
            member_group_ids     => $member_groups->{$data->{'group_id'}} || [],
            owners               => $group_owners,
        });
        $list->push($group) if defined $group;
    }
    
    return $list;
}

=item createByOwner($person [, $application_id])

=cut

sub createByOwner {
    my $self = shift;
    my $person = shift;
    my $application_id = shift;

    my $list = Solstice::List->new();

    return $list unless defined $person and $person->getID();

    my @params = ($person->getID());

    my $where = '';
    if (defined $application_id) {
        $where = ' AND g.application_id = ?';
        push @params, $application_id;
    }

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT g.group_id
        FROM $db_name.Groups AS g, $db_name.GroupOwner AS go
        WHERE g.group_id = go.group_id AND g.is_visible = 1
            AND go.person_id = ?$where", @params);

    my @group_ids;
    while (my $data = $db->fetchRow()) {
        push @group_ids, $data->{'group_id'};
    }

    return $self->createByIDs(\@group_ids);
}

=item createByMember($person)

=cut

sub createByMember {
    my $self = shift;
    my $person = shift;
    my $list = Solstice::List->new();

    return $list unless defined $person and $person->getID();

    return $self->createByIDs($self->createIDsByMember($person));
}

=item createIDsByMember($person)

=cut

sub createIDsByMember {
    my $self = shift;
    my $person = shift;
    
    my @group_ids = ();

    return \@group_ids unless defined $person and $person->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT g.group_id
        FROM '.$db_name.'.Groups AS g, '.$db_name.'.PeopleInGroup AS pg
        WHERE g.group_id = pg.group_id
            AND g.is_visible = 1 AND pg.person_id = ?', $person->getID());

    while (my $data = $db->fetchRow()) {
        push @group_ids, $data->{'group_id'};
    }

    $db->readQuery('SELECT g.group_id 
        FROM '.$db_name.'.Groups AS g, '.$db_name.'.RemoteGroupsInGroup AS rgg, '.$db_name.'.PeopleInRemoteGroup AS prg
        WHERE g.is_visible = 1 AND g.group_id = rgg.parent_group_id
            AND rgg.remote_group_id = prg.remote_group_id AND prg.person_id = ?',
    $person->getID());

    while (my $data = $db->fetchRow()) {
        push @group_ids, $data->{'group_id'};
    }

    return \@group_ids;    
}

=item createByHavingRemoteGroups($source_id)

=cut

sub createByHavingRemoteGroups {
    my $self = shift;
    my $remote_group_source_id = shift;

    my @params = ();
    my $where = '';
    if (defined $remote_group_source_id) {
        $where = ' AND rg.remote_group_source_id = ?';
        push @params, $remote_group_source_id;
    }

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT DISTINCT g.group_id
        FROM $db_name.Groups AS g, $db_name.RemoteGroupsInGroup AS rgg,
            $db_name.RemoteGroup AS rg
        WHERE g.group_id = rgg.parent_group_id
            AND rg.remote_group_id = rgg.remote_group_id
            AND rg.remote_key != 0 AND g.is_visible = 1$where", @params);

    my @group_ids = ();
    while (my $data = $db->fetchRow()) {
        push @group_ids, $data->{'group_id'};
    }

    return $self->createByIDs(\@group_ids);
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
