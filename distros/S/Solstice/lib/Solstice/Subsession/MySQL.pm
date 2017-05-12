package Solstice::Subsession::MySQL;

=head1 NAME

Solstice::Subsession - The Solstice implementation of the "continuation" concept.  Allows branchable sessions.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Subsession);

use Data::Dumper;
use Solstice::Configure;
use Solstice::Database;
use Compress::Zlib qw(compress uncompress);
use Digest::MD5;

use constant TRUE  => 1;
use constant FALSE => 0;

sub _loadSubsessionByID {
    my ($pkg, $id) = @_;

    return unless $id;

    my $self;

    my $config = Solstice::Configure->new();
    my $database_name = $config->getSessionDB();
    my $db = Solstice::Database->new();

    $db->readQuery('SELECT data FROM '.$database_name.'.Subsession WHERE subsession_id = ?', $id);
    my $data = $db->fetchRow();
    my $serialized_subsession = $data->{'data'};

    my $VAR1;
    if ($serialized_subsession) {
        eval uncompress($serialized_subsession); ## no critic
        die "Failed to unthaw subsession $id: $@" if $@;
        $self = $VAR1;
    }else{
        return undef; 
    }

    return $self;
}

sub _store {
    my $self = shift;
    my $subsession_id = shift;
    my $chain_id = shift;
    my $session_id = shift;

    my $config = Solstice::Configure->new();
    my $database_name = $config->getSessionDB();
    my $sol_db_name = $config->getDBName();

    my $db = Solstice::Database->new();

    my $subsession_data;
    {
        local $Data::Dumper::Purity = 1;
        local $Data::Dumper::Indent= 0;
        $subsession_data = Dumper $self;
    }

    #    $session_data = compress($session_data, COMPRESSION_LEVEL);
    #    God DAMN it, the version of compress zlib on the production cluster is 5 years old!
    #    we can't choose a compression level
    $subsession_data = compress($subsession_data);

    # We shouldn't need to do this, but if we do something silly, like store a session, modify
    # a value, and then store it again, we should get a new lock...
    $db->writeQuery("use $database_name");
    $db->writeQuery('REPLACE INTO '.$database_name.'.Subsession
        (subsession_id, chain_id, session_id, data)
        VALUES 
        (?, ?, ?, ?)', 
        $subsession_id, $chain_id, $session_id, $subsession_data);
    $db->writeQuery("use $sol_db_name");
}



sub _isSubsessionLegal {
    my $self = shift;
    my $subsession_id = shift;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();

    my $sql = 'SELECT subsession_id FROM '.$config->getSessionDB().'.Subsession WHERE subsession_id =?';
    $db->readQuery($sql, $subsession_id);

    my $check_id;
    if($db->rowCount()){
        $check_id = $db->fetchRow()->{'subsession_id'};
    }

    return $check_id ? TRUE : FALSE;
}


sub _getFallbackSubsession {
    my $self = shift;
    my $chain_id = shift;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();

    # Rather than start a new chain, try to resume the chain the page was on, if possible.
    $db->readQuery('SELECT subsession_id FROM '.$config->getSessionDB().'.Subsession WHERE chain_id = ?', $chain_id);

    my $subsession;
    if (my $data = $db->fetchRow()) {
        $subsession = Solstice::Subsession->new($data->{'subsession_id'});
    }

    return $subsession;
}


sub _deleteSubsessionsInChain {
    my $self = shift;
    my $chain_id = shift;

    my $database_name = Solstice::Configure->new()->getSessionDB();
    my $sol_db_name = Solstice::Configure->new()->getDBName();
    my $db = Solstice::Database->new();
    $db->writeQuery("use $database_name");
    $db->writeQuery('DELETE FROM Subsession WHERE chain_id = ?', $chain_id);
    $db->writeQuery("use $sol_db_name");
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
