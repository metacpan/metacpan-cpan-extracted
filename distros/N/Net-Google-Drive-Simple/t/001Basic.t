######################################################################
# Test suite for Net::Google::Drive::Simple
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use FindBin qw( $Bin );
use Test::More;

my $nof_tests      = 13;
my $nof_live_tests = $nof_tests - 1;
plan tests => $nof_tests;

use Net::Google::Drive::Simple;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init( { level => $DEBUG, layout => "%F{1}:%L> %m%n" } );

my $gd = Net::Google::Drive::Simple->new();

ok 1, "loaded ok";

SKIP: {
    if( !$ENV{ LIVE_TEST } ) {
        skip "LIVE_TEST not set, skipping live tests", $nof_live_tests;
    }

    my( $files, $parent ) = $gd->children( "/this-path-does-not-exist",
        { maxResults => 3 }, { page => 0 },
    );

    ok !defined $files, "non-existent path";
    is $gd->error(),
      "Child this-path-does-not-exist not found",
      "error message";

    ( $files, $parent ) = $gd->children( "/",
        { maxResults => 3 }, { page => 0 },
    );
    is ref($files), "ARRAY", "children returned ok";

    # upload a test file
    my $testfile = "$Bin/data/testfile";
    my $file_id = $gd->file_upload( $testfile, $parent );
    ok defined $file_id, "upload ok";
    my $metadata = $gd->file_metadata( $file_id );
    ok (((defined $metadata) && ($metadata->{title} eq 'testfile')), "metadata ok");

    # Search for the file as both children method
    # and the 'files' method (direct api access)
    ( $files, $parent ) = $gd->children( "/", {}, { title => 'testfile' } );
    ok( ref($files) eq "ARRAY" && scalar(@$files), "file founds via children()" );
    is( $files->[0]->originalFilename(), "testfile", "Got the file, original filename looks right (via children())");
    $files = $gd->files( {}, { title => 'testfile' } );
    ok( ref($files) eq "ARRAY" && scalar(@$files), "files found via files()" );
    is( $files->[0]->originalFilename(), "testfile", "Got the file, original filename looks right (via files())");

    # Delete the file
    ok $gd->file_delete( $file_id ), "delete ok";

    ( $files, $parent ) = $gd->children( "/", {}, { title => 'testfile' } );
    ok( ref($files) eq "ARRAY" && !scalar(@$files), "Can no longer find deleted file (via children())" );
    $files = $gd->files( {}, { 'title' => 'testfile' } );
    ok( ref($files) eq "ARRAY" && !scalar(@$files), "Can no longer find deleted file (via files)" );
}
