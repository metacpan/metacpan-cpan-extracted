package Solstice::Subsession;

=head1 NAME

Solstice::Subsession - The Solstice implementation of the "continuation" concept.  Allows branchable sessions.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use Data::Dumper;
use Solstice::Configure;
use Solstice::Database;
use Compress::Zlib qw(compress uncompress);
use Digest::MD5;

use constant TRUE  => 1;
use constant FALSE => 0;

sub new {
    my $pkg = shift; 
    $pkg = 'Solstice::Subsession::' .$pkg->getConfigService()->getSessionBackend();
    Solstice->loadModule($pkg);
    my ($id) = @_;


    my $self;

    if($id){
        $self = $pkg->_loadSubsessionByID($id);
    }else{
        $self = bless {}, $pkg;
        $self->setChainID($self->_generateID());
        $self->revision(); #get an initial id
    }

    return $self;
}

sub revision {
    my $self = shift;
    $self->_setID($self->_generateID());
}


sub setChainID {
    my $self = shift;
    $self->{'_chain_id'} = shift;
}

sub getChainID {
    my $self = shift;
    return $self->{'_chain_id'};
}

sub _setID {
    my $self = shift;
    $self->{'_id'} = shift;
}

sub getID {
    my $self = shift;
    return $self->{'_id'};
}

sub store {
    my $self = shift;
    my $session_id = shift; 
    my $subsession_id = $self->getID();
    my $chain_id = $self->getChainID();

    die "Storing a subsession with no subsession id\n" unless $subsession_id;
    die "Storing a subsession with no chain id\n" unless $chain_id;

    $self->_store($subsession_id, $chain_id, $session_id);
}

sub getFallbackSubsession {
    my $self = shift;
    my $chain_id = shift;

    my $subsession = $self->_getFallbackSubsession($chain_id);
    $subsession = Solstice::Subsession->new() unless $subsession;
    return $subsession;
}


sub isSubsessionLegal {
    my $self = shift;
    my $subsession_id = shift;
    return $self->_isSubsessionLegal($subsession_id);
}

sub _isSubsessionLegal {
    die "_isSubsessionLegal must be implented in the Subssion backend.";
}


sub _generateID {
    my $self = shift;
    return Digest::MD5::md5_hex( time().{}.rand().$$ );
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
