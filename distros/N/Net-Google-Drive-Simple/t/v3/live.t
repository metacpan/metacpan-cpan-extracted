######################################################################
# Test suite for Net::Google::Drive::Simple::V3
# by Sawyer X <xsawyerx@cpan.org>
######################################################################
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename ();
use Test::More;

my $nof_tests      = 15;
my $nof_live_tests = $nof_tests - 1;
plan tests => $nof_tests;

use Net::Google::Drive::Simple;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init( { level => $DEBUG, layout => "%F{1}:%L> %m%n" } );

my $gd = Net::Google::Drive::Simple->new( 'version' => 3 );

ok( 1, 'Loaded ok' );

SKIP: {
    if ( !$ENV{'LIVE_TEST'} ) {
        skip "LIVE_TEST not set, skipping live tests", $nof_live_tests;
    }

    my $files = $gd->children(
        "/this-path-does-not-exist",
        { 'pageSize'    => 3 },
        { 'auto_paging' => 0 },
    );

    ok( !defined $files, "non-existent path" );
    is(
        $gd->error(),
        "Child this-path-does-not-exist not found",
        "error message",
    );

    $files = $gd->children(
        '/',
        { 'pageSize' => 3 }, { 'auto_paging' => 0 },
    );
    is( ref($files), "ARRAY", "children returned ok" );

    # upload a test file
    my $testfile = "$Bin/../data/testfile";

    #my $file_data = $gd->upload_media_file($testfile);
    my $file_data = $gd->upload_multipart_file($testfile);
    my $file_id   = $file_data->{'id'};

    ok( defined $file_id, "upload ok" );
    my $metadata = $gd->file_metadata($file_id);
    ok( ( ( defined $metadata ) && ( $metadata->{'name'} eq 'testfile' ) ), "metadata ok" );

    # Search for the file as both children method
    # and the 'files' method (direct api access)
    $files = $gd->children( "/", { 'fields' => 'files/originalFilename' }, { 'name' => 'testfile' } );
    ok( ref($files) eq "ARRAY" && scalar(@$files), "file founds via children()" );

    is( $files->[0]->originalFilename(), "testfile", "Got the file, original filename looks right (via children())" );
    $files = $gd->files( { 'q' => 'name = "testfile"', 'fields' => 'files(originalFilename,trashed)' } );
    isa_ok( $files, 'HASH' );
    $files = [ grep !$_->{'trashed'}, @{ $files->{'files'} } ];
    ok( ref($files) eq "ARRAY" && scalar(@$files), "files found via files()" );
    is( $files->[0]->{'originalFilename'}, "testfile", "Got the file, original filename looks right (via files())" );

    # Delete the file
    ok( $gd->delete_file($file_id), "delete ok" );

    $files = $gd->children( '/', {}, { 'name' => 'testfile' } );
    ok( ref($files) eq "ARRAY" && !scalar(@$files), "Can no longer find deleted file (via children())" );
    $files = $gd->files( { 'q' => 'name = "testfile"', 'fields' => 'files(originalFilename,trashed)' } );
    isa_ok( $files, 'HASH' );
    $files = [ grep !$_->{'trashed'}, @{ $files->{'files'} } ];
    ok( ref($files) eq "ARRAY" && !scalar(@$files), "Can no longer find deleted file (via files)" );
}
