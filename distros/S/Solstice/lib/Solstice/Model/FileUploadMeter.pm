package Solstice::Model::FileUploadMeter;

# $Id: $

=head1 NAME

Solstice::Model::FileUploadMeter

=head1 SYNOPSIS

    use Solstice::Model::FileUploadMeter;

    my $model = Solstice::Model::FileUploadMeter->new();

=head1 DESCRIPTION

Tracks the progress of an uploading file.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Model);

use Solstice::DateTime;
use Solstice::Database;
use Digest::MD5 qw(md5_hex);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4


=item new()

Constructor.

=cut

sub new {
    my $class = shift;

    my $input = shift;
    my $self = $class->SUPER::new(@_);

    if (defined $input) {
        if (ref $input eq "HASH") {
            return unless $self->_initFromHex($input->{'hex_key'});
        }
        else {
            return unless $self->_init($input);
        }
    }

    return $self;
}

sub _init {
    my $self = shift;
    my $key  = shift;

    $key = md5_hex($key);

    return $self->_initFromHex($key);
}

sub _initFromHex {
    my $self = shift;
    my $key  = shift;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery("SELECT file_upload_progress_id, filesize, uploaded, date_started, upload_key FROM $db_name.FileUploadProgress WHERE upload_key = ?", $key);

    if (my $data = $db->fetchRow()) {
        $self->_setFileKey($data->{'upload_key'});
        $self->_setID($data->{'file_upload_progress_id'});
        $self->_setFileSize($data->{'filesize'});
        $self->_setUploadSize($data->{'uploaded'});
        $self->_setDateStarted(Solstice::DateTime->new($data->{'date_started'}));
        return TRUE;
    }
    return FALSE;
}

sub store {
    my $self = shift;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    my @values = ($self->getFileSize(), $self->getUploadSize(), $self->getDateStarted()->toSQL(), $self->getFileKey());

    if (defined $self->getID()) {
        $db->writeQuery("UPDATE $db_name.FileUploadProgress SET filesize = ?, uploaded = ?, date_started = ?, upload_key = ? WHERE file_upload_progress_id = ?", @values, $self->getID());
    }
    else {
        $db->writeQuery("INSERT INTO $db_name.FileUploadProgress (filesize, uploaded, date_started, upload_key) VALUES (?, ?, ?, ?)", @values);
        $self->_setID($db->getLastInsertID());
    }
}

=back

=head2 Private Methods

=over 4

=cut


=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name        => 'FileSize',
            key         => '_file_size',
            type        => 'Integer',
        },
        {
            name        => 'UploadSize',
            key         => '_upload_size',
            type        => 'Integer',
        },
        {
            name        => 'FileKey',
            key         => '_file_key',
            type        => 'String',
        },
        {
            name        => 'DateStarted',
            key         => '_date_started',
            type        => 'DateTime',
        },
    ];
}


1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::Model>,
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
