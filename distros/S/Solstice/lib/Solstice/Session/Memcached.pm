package Solstice::Session::Memcached;

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Session);


use Solstice::Memcached;

sub _store {
    my $self = shift;
    my $session_id = shift;

    my $memd = Solstice::Memcached->new('sessions');
    $memd->set($session_id, $self);
    return;
}


sub _loadSessionByID {
    my $pkg = shift;
    my $session_id = shift;


    my $memd = Solstice::Memcached->new('sessions');
    my $self = $memd->get($session_id);

    return $self;
}

sub _getSessionLock {
}

sub _releaseSessionLock {
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

