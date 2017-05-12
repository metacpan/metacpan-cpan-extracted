package Solstice::Server::Lighttpd;

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Server::SimpleCGI);

use constant TRUE   => 1;
use constant FALSE  => 0;

use Solstice::Dispatch;

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new();
    Solstice::Dispatch::dispatch();

    return $self;
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

