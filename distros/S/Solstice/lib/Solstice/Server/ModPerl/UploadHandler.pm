package Solstice::Server::ModPerl::UploadHandler;

=head1 NAME

Solstice::Server::ModPerl::UploadHandler - Gathers data about file uploads.

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice);

use Solstice::Configure;
use Solstice::Database;
use Solstice::Model::FileUploadMeter;
use Solstice::Server::ModPerl::API;
use Solstice::CGI;
use Time::HiRes qw(gettimeofday tv_interval);
use Digest::MD5 qw(md5_hex);

my %file_sizes;
my %last_updates;

sub handler {
    my $r = shift;

    $r = Solstice::Server::ModPerl::API->new($r);

    # We need to use this rather than Solstice::CGI, because using
    # Solstice::CGI will force us to wait for the file to upload before
    # we can get any CGI values.  Also, I'm not clear on why I need to a mp1/2
    # switch here, but the first method breaks the whole shebang for 1.3,
    # with a similar effect to Solstice::CGI.  Returns the same value though ;(
    my $key;
    if($r->is2()){
        $key = $r->apacheRequest()->param('upload_key');
    }else{
        my %args = $r->args();
        $key = $args{'upload_key'};
    }

    return unless defined $key;
    $key = md5_hex($key);

    my $handler = sub {
        my $upload = shift;
        my $data = shift;
        my $dlength = shift;
        my $dkey = shift;

        my $length;
        if($r->is2()){
            $length = $data ? do{ use bytes; length($data);} : 0;
        }else{
            $length = $dlength;
        }

        $file_sizes{$key} += $length;
        _periodicDBUpdate($key, $file_sizes{$key});
    };

    my $q;
    if($r->is2()){
        $q = Apache2::Request->new($r->request(), UPLOAD_HOOK => $handler);
    }else{
        $q = Apache::Request->instance($r->request(), HOOK_DATA => $key, UPLOAD_HOOK => $handler);
    }

    _initialDBEntry($r, $key);
    my $uploaded = $q->upload();
    _finalDBEntry($r, $key);

    return;
}

=item _periodicDBUpdate()
=cut

sub _periodicDBUpdate {
    my $key = shift;
    my $length = shift;
    if (tv_interval($last_updates{$key}, [gettimeofday]) > 0.5) {

        my $upload_meter = Solstice::Model::FileUploadMeter->new({ hex_key => $key });
        if (defined $upload_meter) {
            $upload_meter->setUploadSize($length);
            $upload_meter->store();
        }

        $last_updates{$key} = [gettimeofday];
    }
}

sub _initialDBEntry {
    my $r = shift;
    my $key = shift;
    $last_updates{$key} = [gettimeofday];

    my $rsize = $r->header_in("Content-Length");

    my $upload_meter = Solstice::Model::FileUploadMeter->new();
    $upload_meter->setFileKey($key);
    $upload_meter->setFileSize($rsize);
    $upload_meter->setUploadSize(0);
    $upload_meter->setDateStarted(Solstice::DateTime->new(time));

    $upload_meter->store();
}

sub _finalDBEntry {
    my $r = shift;
    my $key = shift;

    my $upload_meter = Solstice::Model::FileUploadMeter->new({ hex_key => $key });
    if (defined $upload_meter) {
        $upload_meter->setUploadSize($upload_meter->getFileSize());
        $upload_meter->store();
    }

    delete $file_sizes{$key};
    delete $last_updates{$key};
}

1;

__END__

=back

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
