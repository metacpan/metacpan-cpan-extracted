package Solstice::ConfigService;

# $Id: ConfigService.pm 3152 2006-02-21 18:02:20Z mcrawfor $

=head1 NAME

Solstice::ConfigService - Provides configuration info to the Solstice Framework.

=head1 SYNOPSIS

use Solstice::ConfigService;

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Configure);

our ($VERSION) = ('$Revision: 2061 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service::Memory|Solstice::Service::Memory>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut




=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::ConfigService';
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Service::Memory|Solstice::Service::Memory>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2061 $



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
