package Solstice::Subsession::Memcached;

=head1 NAME

Solstice::Subsession - The Solstice implementation of the "continuation" concept.  Allows branchable sessions.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Subsession);

use Solstice::Memcached;

use constant TRUE  => 1;
use constant FALSE => 0;

sub _loadSubsessionByID {
    my ($pkg, $id) = @_;

    return unless $id;

    my $memd = Solstice::Memcached->new('sessions');
    my $self = $memd->get("subsession-$id");
    return unless $self;

    return $self;
}

sub _store {
    my $self = shift;
    my $subsession_id = shift;
    my $chain_id = shift;

    my $memd = Solstice::Memcached->new('sessions');
    $memd->set("subsession-".$subsession_id, $self);

    my $chain_tracker = $memd->get("chain_tracker-".$chain_id) || [];
    push @$chain_tracker, $subsession_id;
    $memd->set("chain_tracker-".$chain_id, $chain_tracker);
}

sub _isSubsessionLegal {
    my $self = shift;
    my $subsession_id = shift;

    return unless $subsession_id;

    my $memd = Solstice::Memcached->new('sessions');

    return $memd->get("subsession-$subsession_id") ? TRUE : FALSE;
}


sub _getFallbackSubsession {
    my $self = shift;
    my $chain_id = shift;

    return unless $chain_id;

    my $memd = Solstice::Memcached->new('sessions');
    my $chain_tracker = $memd->get("chain_tracker-".$chain_id);
    if($chain_tracker && scalar @$chain_tracker){
        return $memd->get("subsession-". $chain_tracker->[scalar(@$chain_tracker) - 1]);
    }

    return;
}


sub _deleteSubsessionsInChain {
    my $self = shift;
    my $chain_id = shift;

    return unless $chain_id;

    my $memd = Solstice::Memcached->new('sessions');
    my $ids = $memd->get("chain_tracker-$chain_id") || [];

    for my $id (@$ids){
        $memd->delete("subsession-$id");
    }
    $memd->set("chain_tracker-$chain_id", []);
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
