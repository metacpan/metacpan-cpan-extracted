package Solstice::View::Resource::File::Download; 

# $Id: Download.pm 1 2006-04-10 14:15:08Z user $

=head1 NAME

Solstice::View::Resource::File::Download -

=head1 SYNOPSIS

  # See L<Solstice::View> for usage.

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::Download);

use Solstice::CGI;
use Solstice::Server;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 191 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item setIsInline($bool)

=cut

sub setIsInline {
    my $self = shift;
    $self->{'_is_inline'} = shift;
}

=item getIsInline()

=cut

sub getIsInline {
    my $self = shift;
    return $self->{'_is_inline'} ||
        $self->getButtonService()->getAttribute('inline');
}

=item setIsThumbnail($bool)

=cut

sub setIsThumbnail {
    my $self = shift;
    $self->{'_thumbnail'} = shift;
}

=item getIsThumbnail()

=cut

sub getIsThumbnail {
    my $self = shift;
    return $self->{'_thumbnail'};
}

=item printData()

=cut

sub printData {
    my $self = shift;
    
    my $file = $self->_getFile();
    
    if (defined $file) {
        $file->get(*STDOUT);
    }
}

=item sendHeaders()

=cut

sub sendHeaders {
    my $self = shift;
   
    my $file = $self->_getFile();

    my $server = Solstice::Server->new();

    if (!defined $file) {
        $server->setStatus(404);
        return;
    }

    my $ct_service = $self->getContentTypeService();
    
    my $filename = $file->getName() || 'file';
    my $size     = $file->getSize() || 0;
    # We can either send the application/x-download type, or the real type.
    # Since the content-disposition: attachment forces the save dialog, and
    # sending the real type works better in firefox (and no worse in IE) 
    # we're sending the real type
    my $type = $ct_service->getDownloadContentType($file->getContentType());
   
    # Append a file extension
    unless ($filename =~ /\.([\w-]+)$/) {
        my $extension = $ct_service->getExtensionByContentType($type);
        $filename .= ('.' . $extension) if defined $extension;
    }
    $filename =~ s/"/\\"/g;

    my $disp = $self->getIsInline() ? 'inline' : 'attachment';

    $server->setContentDisposition($disp.'; filename="'.$filename.'"');
    $server->setContentLength($size) if $size;
    $server->setContentType($type);
}


=item _getFile()

This can be overridden in a subclass.

=cut

sub _getFile {
    my $self = shift;
    my $file = $self->getModel();

    return unless defined $file;
    return $file->makeThumbnail(param('s')) if $self->getIsThumbnail();
    return $file;
}


1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 191 $

=head1 SEE ALSO

L<WebQ::View|WebQ::View>,
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
