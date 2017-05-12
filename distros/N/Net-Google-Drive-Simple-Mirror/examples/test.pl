#!/usr/bin/perl

# This program requires
# a Google Drive access token in '~/.google-drive.yml',
# a folder 'Mirror/Test/Folder' in your Google Drive,
#   Mirror
#        `--Test
#              `--Folder
# and a local folder 'test_data_mirror'.
#
# Also put some files in your Google Drive test folder.

use Modern::Perl;
use Method::Signatures;

use lib '../lib';
use Net::Google::Drive::Simple::Mirror;

say "-----------------------------------------------------------------";
say "Show all remote files and their local representation, no download";
say "-----------------------------------------------------------------";

my $google_docs = Net::Google::Drive::Simple::Mirror->new(
    remote_root   => 'Mirror/Test/Folder',
    local_root    => 'test_data_mirror',
    export_format => ['opendocument','html'],
    # verbosely download nothing:
    download_condition => sub {
        my ($self, $remote_file, $local_file) = @_;
        say "Remote:     ", $remote_file->title();
        say "`--> Local: $local_file";
        return 0;
    }
);

$google_docs->mirror();
