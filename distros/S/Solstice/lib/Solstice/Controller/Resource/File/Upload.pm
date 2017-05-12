package Solstice::Controller::Resource::File::Upload;

# $Id: $

=head1 NAME

Solstice::Controller::Resource::File::Upload -

=head1 SYNOPSIS

  # See L<Solstice::Controller> for usage.

=head1 DESCRIPTION

This uploads a file, and then prints out a little page that has the encrypted file id.
This is part of the upload system, the output is designed to be consumed by javascript.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller);

use Solstice::CGI qw(param upload);
use Solstice::Resource::File::BlackBox;
use Solstice::View::Resource::File::Upload;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut


=item new()

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $upload = upload('file');

    # Ensure that enough data exists to create the file
    unless (defined $upload &&
            defined $upload->getName() &&
            defined $upload->getFileHandle()) {
        return $self;
    }

    my $filename = $upload->getName();
    
    # Some clients insist on sending a full path
    if ($filename =~ /^.*\\(.*)$/) { $filename = $1; }
    
    my $file = Solstice::Resource::File::BlackBox->new();
    $file->setName($filename);
    $file->put($upload);

    if ($self->_storeFile($file)) {
        $self->setModel($file);
    }

    return $self;
}

=item getView()

=cut

sub getView {
    my $self = shift;
    my $file = $self->getModel();

    if (defined $file) {
        $self->_processFile($file);
    }

    return Solstice::View::Resource::File::Upload->new($file);
}

=item _storeFile($file)

Provides a store-context hook for subclasses to implement.

=cut

sub _storeFile {
    my $self = shift;
    my $file = shift;
    return $file->store();
}

=item _processFile($file)

Provides a post-store hook for subclasses to implement.

=cut

sub _processFile {
    return TRUE;
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::Controller>,
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
