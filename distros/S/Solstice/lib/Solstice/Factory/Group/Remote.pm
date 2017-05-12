package Solstice::Factory::Group::Remote;

=head1 NAME

Solstice::Factory::Group::Remote - Has the ability to create remote group objects.

=head1 SYNOPSIS

my $factory = Solstice::Factory::Group::Remote->new();
my $list = $factory->createByIDs(\@group_ids);

=head1 DESCRIPTION

This object has the ability to create remote groups.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Factory);

use Solstice::Database;
use Solstice::DateTime;
use Solstice::List;

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

    $db->readQuery("SELECT rg.*, rgs.package
        FROM $db_name.RemoteGroup AS rg
        JOIN $db_name.RemoteGroupSource AS rgs USING(remote_group_source_id)
        WHERE rg.remote_key != 0 AND rg.remote_group_id IN ($select_string)",
        @$ids);

    while (my $data = $db->fetchRow()) {
        my $remote_group = $self->_createRemoteGroupFromDBData($data);
        $list->push($remote_group) if defined $remote_group;
    }
    
    return $list;
}

=item createByGroupID($group_id)

=cut

sub createByGroupID {
    my $self = shift;
    my $group_id = shift;
    my $list = Solstice::List->new();

    return $list unless defined $group_id;
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT rg.*, rgs.package
        FROM $db_name.RemoteGroupsInGroup AS rgg
            JOIN $db_name.RemoteGroup AS rg USING(remote_group_id)
            JOIN $db_name.RemoteGroupSource AS rgs USING(remote_group_source_id)
        WHERE rgg.parent_group_id = ?", $group_id);

    while (my $data = $db->fetchRow()) {
        my $remote_group = $self->_createRemoteGroupFromDBData($data);
        $list->push($remote_group) if defined $remote_group;
    }
    
    return $list;
}

=item createHashByGroupIDs(\@group_ids)

=cut

sub createHashByGroupIDs {
    my $self = shift;
    my $group_ids = shift;
    my $remote_groups = {};

    return $remote_groups unless defined $group_ids && scalar @$group_ids;

    my $select_string = join ',', map { '?' } @$group_ids;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT rgg.parent_group_id, rg.*, rgs.package
        FROM $db_name.RemoteGroupsInGroup AS rgg
        JOIN $db_name.RemoteGroup AS rg USING(remote_group_id)
        JOIN $db_name.RemoteGroupSource AS rgs USING(remote_group_source_id)
        WHERE rg.remote_key != 0 AND rgg.parent_group_id IN ($select_string)
        ", @$group_ids);

    while (my $data = $db->fetchRow()) {
        my $remote_group = $self->_createRemoteGroupFromDBData($data);
        next unless defined $remote_group;
        $remote_groups->{$data->{'parent_group_id'}}->{$data->{'remote_group_id'}} = $remote_group;
    }

    return $remote_groups;
}

=item createBySourceID($source_id)

=cut

sub createBySourceID {
    my $self = shift;
    my $source_id = shift;
    my $list = Solstice::List->new();

    return $list unless defined $source_id;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery("SELECT rg.*, rgs.package
        FROM $db_name.RemoteGroup AS rg
        JOIN $db_name.RemoteGroupSource AS rgs USING(remote_group_source_id)
        WHERE rg.remote_key != 0 AND rg.remote_group_source_id = ?",
        $source_id);

    while (my $data = $db->fetchRow()) {
        my $remote_group = $self->_createRemoteGroupFromDBData($data);
        $list->push($remote_group) if defined $remote_group;
    }
    
    return $list;
}

=item createBySourceIDAndDate($source_id, $datetime)

Returns a list of remote groups containing the passed $source_id and
created on or after the passed $datetime.

=cut

sub createBySourceIDAndDate {
    my $self = shift;
    my $source_id = shift;
    my $datetime  = shift;
    my $list = Solstice::List->new();

    return $list unless (defined $source_id &&
        defined $datetime && $datetime->isValid());

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT rg.*, rgs.package
        FROM $db_name.RemoteGroup AS rg
        JOIN $db_name.RemoteGroupSource AS rgs USING(remote_group_source_id)
        WHERE rg.remote_key != 0 AND rg.remote_group_source_id = ?
            AND date_created >= ?
        ORDER BY rg.date_created", $source_id, $datetime->toSQL());

    while (my $data = $db->fetchRow()) {
        my $remote_group = $self->_createRemoteGroupFromDBData($data);
        $list->push($remote_group) if defined $remote_group;
    }

    return $list;
}

=item _createRemoteGroupFromDBData(\%data)

=cut

sub _createRemoteGroupFromDBData {
    my $self = shift;
    my $data = shift;

    return unless defined $data;

    my $package = $data->{'package'};
    $self->loadModule($package);

    return $package->new({
        id                  => $data->{'remote_group_id'},
        remote_source_id    => $data->{'remote_group_source_id'},
        remote_key          => $data->{'remote_key'},
        name                => $data->{'name'},
        modification_date   => Solstice::DateTime->new($data->{'date_modified'}),
        creation_date       => Solstice::DateTime->new($data->{'date_created'}),
        reconciliation_date => Solstice::DateTime->new($data->{'date_reconciled'}),
    });
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
