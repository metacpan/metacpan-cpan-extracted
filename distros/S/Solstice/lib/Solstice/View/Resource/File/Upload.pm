package Solstice::View::Resource::File::Upload;

# $Id: $

=head1 NAME

Solstice::View::Resource::File::Upload - 

=head1 SYNOPSIS

  # See L<Solstice::View> for usage.

=head1 DESCRIPTION

This uploads a file, and then prints out a little page that has the encrypted file id.
This is part of the upload system; the output is designed to be consumed by javascript.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::Download);

use Solstice::Encryption;
use Solstice::Server;
use Solstice::StringLibrary qw(truncstr);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut


=item printData()

=cut

sub printData {
    my $self = shift;
    
    my $file = $self->getModel();
    
    if (defined $file && $file->getID()) {
        my $encryption = Solstice::Encryption->new();
        my $enc_id = $encryption->encrypt('file_'.$file->getID());
    
        my $type = $file->getContentType();
        my $filename = truncstr($file->getName(), 35);
    
        print '<html><body>'.
            '<input type="hidden" id="file_key" value="'.$enc_id.'"/>'.
            '<input type="hidden" id="file_url" value="'.$file->getTicketURL().'"/>'.
            '<input type="hidden" id="file_size" value="'.$file->getSize().'"/>'.
            '<input type="hidden" id="file_name" value="'.$filename.'"/>'.
            '<input type="hidden" id="file_desc" value="'.$self->getContentTypeService()->getContentDescriptionByContentType($type).'"/>'.
            '<input type="hidden" id="file_icon" value="'.$self->getIconService()->getIconByType($type).'"/>'.
            '</body></html>';
    } else {
        print '<html><body><input type="hidden" id="file_error" value="Error"/></body></html>';
    }
}

=item sendHeaders()

=cut

sub sendHeaders {
    my $self = shift;
    Solstice::Server->new()->setContentType('text/html');
}


1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::View::Download>,
L<perl>.

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
