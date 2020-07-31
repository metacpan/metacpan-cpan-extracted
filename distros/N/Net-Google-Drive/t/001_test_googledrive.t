#
#===============================================================================
#
#         FILE: 002_test_googledrive.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 28.09.2018 23:14:47
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use lib 'lib';
use File::Basename;
use File::Spec;
use Net::Google::Drive;
use LWP::UserAgent;

use Test::More 'no_plan';

BEGIN {
    use_ok("Net::Google::Drive");
}

my $CLIENT_ID       = $ENV{GOOGLE_CLIENT_ID}        // '593952972427-e6dr18ua0leurrjtu9gl1766t1je1num.apps.googleusercontent.com';
my $CLIENT_SECRET   = $ENV{GOOGLE_CLIENT_SECRET}    // 'pK99-WlEd7kr7YcWIAVFOQpu';
my $ACCESS_TOKEN    = $ENV{GOOGLE_ACCESS_TOKEN}     // 'ya29.GlspBipu9sdZKYmO4t90eDiEUVIQ2mhIVuPWothJa2Xwihow_ka889DFPWt3GSSrSpvh3mWjKUCDn-QlRxZRxBuCuaRDFZ5Q9w2w5SHFYOn6f_F2JASA34xgbakr';
my $REFRESH_TOKEN   = $ENV{GOOGLE_REFRESH_TOKEN}    // '1/uKe_YszQbrwA6tHI5Att-VOYuktWt5iV9Q5fy-DrEjE';

my $TEST_DOWNLOAD_FILE  = File::Spec->catfile('t', 'test_download');
my $TEST_UPLOAD_FILE    = File::Spec->catfile('t', 'gogle_upload_file');


unlink ($TEST_DOWNLOAD_FILE);

my $drive = Net::Google::Drive->new(
                                        -client_id      => $CLIENT_ID,
                                        -client_secret  => $CLIENT_SECRET,
                                        -access_token   => $ACCESS_TOKEN,
                                        -refresh_token  => $REFRESH_TOKEN,
                                    );
isa_ok($drive, 'Net::Google::Drive');

my $internet_connection = testInternetConnection();

####### TESTS ######
SKIP: {
    if (not $internet_connection) {
        skip "Skip tests: No internet connection";  
    }
    my $test_download_file_id = testSearchFileByName($drive, 'drive_file.t');
    testSearchFileByNameContains($drive, 'Тестовый');

#### Download file
    testDownloadFile($drive, $test_download_file_id);

#### Upload file
    my $upload_file_id = testUploadFile($drive, $TEST_UPLOAD_FILE);
    testSearchFileByName($drive, basename($TEST_UPLOAD_FILE));
#### Get metadata
    testGetFileMetadata($drive, $upload_file_id);
#### Set permission
    testSetFilePermissionWrong($drive, $upload_file_id);
    testSetFilePermission($drive, $upload_file_id, 'anyone');
#### Share file
    testShareFile($drive, $test_download_file_id);

#### Delete file
    testDeleteFile($drive, $upload_file_id);
}

unlink ($TEST_DOWNLOAD_FILE);

sub testInternetConnection {
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get('https://www.google.com');
    return $response->code() == 200;
}

sub testSearchFileByName{
    my ($drive, $name) = @_;
    my $files = $drive->searchFileByName(
                            -filename   => $name,
                        );
    my $success = scalar(@$files) >= 1;
    ok ($success , "Test searchFileByName");
    return $files->[0]->{id};
}

sub testSearchFileByNameContains {
    my ($drive, $filename) = @_;
    my $files = $drive->searchFileByNameContains(
                                -filename   => $filename,
                            );
    is (scalar(@$files), 1, "Test searchFileByNameContains");
}

sub testDownloadFile {
    my ($drive, $file_id) = @_;
    
    my $res = $drive->downloadFile(
                                    -file_id        => $file_id,
                                    -dest_file      => $TEST_DOWNLOAD_FILE,
                                );
    ok($res, 'Test downloadFile() ok');
    ok(-e $TEST_DOWNLOAD_FILE, 'Download file exists');
}

sub testDeleteFile {
    my ($drive, $file_id) = @_;

    my $res = $drive->deleteFile(
                                    -file_id        => $file_id,
                                );
    ok($res, 'Test deleteFile() ok');
}

sub testUploadFile {
    my ($drive, $fname) = @_;

    my $res = $drive->uploadFile(
                                    -source_file    => $fname,
                                );
    ok($res, 'Test upload file');
    my $file_id = $res->{id};
    ok($file_id, "Uploaded file id: $file_id");
    return $file_id;
}

sub testGetFileMetadata {
    my ($drive, $file_id) = @_;

    my $metadata = $drive->getFileMetadata(
                                            -file_id        => $file_id,
                                        );
    ok($metadata, 'Get file metadata');
}

sub testSetFilePermissionWrong {
    my ($drive, $file_id) = @_;
    eval {
        $drive->setFilePermission(
                                                    -file_id        => $file_id,
                                                    -type           => 'test',
                                                    -role           => 13,
                                                );
    };
    like ($@, qr/^Wrong permission/, 'Test wrong permission');
}

sub testSetFilePermission {
    my ($drive, $file_id, $type) = @_;
    my $perm = $drive->setFilePermission(
                                                -file_id        => $file_id,
                                                -type           => $type,
                                                -role           => 'reader',          
                                            );
    is($perm->{type}, $type, 'Test setFilePermission()');
}

sub testShareFile {
    my ($drive, $file_id) = @_;

    my $file_link = $drive->shareFile( -file_id => $file_id );

    like($file_link, qr/^http/, "Test share file link. Link: $file_link");
}
