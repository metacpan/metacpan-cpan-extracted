package Solstice::Controller::Remote::UploadMeter;

# $Id: $

=head1 NAME

Solstice::Controller::Remote::UploadMeter - Fetch progress data about a given file upload

=head1 SYNOPSIS

  # See L<Solstice::Controller::Remote> for usage.
 
=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::Remote);

use Solstice::CGI;
use Solstice::Model::FileUploadMeter;

sub runRemote {
    my $self = shift;

    my $all_data = $self->getModel();

    $self->addAction("Solstice.FileUpload._update_running = false;");

    for my $data (values %$all_data){
        my $key      = $data->{'upload_key'};
        my $frame    = $data->{'frame'};    # Upload instance
        my $position = $data->{'position'}; # upload position id within the instance
        my $total_size   = 0;
        my $current_size = 0;

        my $upload_meter = Solstice::Model::FileUploadMeter->new($key);

        if (defined $upload_meter) {
            $total_size   = $upload_meter->getFileSize() || 0;
            $current_size = $upload_meter->getUploadSize() || 0;
        }

        $self->addAction("Solstice.FileUpload.updateMeter('$total_size', '$current_size', '$key', '$frame', '$position');");
    }
}


1;

__END__

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
