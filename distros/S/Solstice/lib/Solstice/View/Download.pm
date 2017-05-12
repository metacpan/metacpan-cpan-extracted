package Solstice::View::Download;

# $Id: Download.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::View::Download - Superclass for views that present binary or downloadable data instead of web content.

=head1 SYNOPSIS

  package MyView;

  use base qw(Solstice::View::Download);

=head1 DESCRIPTION

This is a virtual class for creating solstice view objects.  This class
should never be instantiated as an object, rather, it should always
be sub-classed.

=cut

use 5.006_000;
use strict;
use warnings;
no warnings qw(redefine);

use base qw(Solstice::View);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported..

=head2 Methods

=over 4

=cut

=item printData()

This method returns the download data. It should be overridden in a subclass.

=cut

sub printData {
    return FALSE;
}

=item isDownloadView()

=cut

sub isDownloadView {
    return TRUE;
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $

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
