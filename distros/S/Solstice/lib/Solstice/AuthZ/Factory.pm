package Solstice::AuthZ::Factory;

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use Solstice::AuthZ::Action;
use Solstice::Database;
use Solstice::Configure;

sub new {
    my $obj = shift;
    return bless {}, $obj;
}


sub createActionsByRole {
    my $self = shift;
    my $role = shift;

    my $role_id = $role->getID();
    die "invalid role passed to AuthZ::Factory" unless $role_id;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery("SELECT Actions.* FROM $db_name.Actions JOIN $db_name.RolePermissions using(action_id) WHERE role_id = ?", $role_id);

    my $actions;

    while( my $row = $db->fetchRow() ){
        push @$actions, Solstice::AuthZ::Action->new($row);
    }
    return $actions;
}

1;
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

