
BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Test::More 1.00;
use Archive::Tar;
use Log::Any::Test;
use Log::Any qw($log);

require_ok('Nexus::Uploader');

# Test logging
{
    Nexus::Uploader->log('Standard log');
    $log->contains_ok( qr/Standard log/, 'Standard logging test' );
    Nexus::Uploader->log_debug('Debug log');
    $log->contains_ok( qr/Debug log/, 'Debug logging test' );
}

# Author test - upload a sample file to Nexus.
{
    skip "Author tests",
        1
        unless my $uploader = Nexus::Uploader->new(
        nexus_URL => 'http://localhost:8081/nexus/content/repositories/releases',
        username  => 'admin',
        password  => 'admin123',
        group     => 'BRAD.SVW',
        artefact  => 'Nexus::Uploader::Test',
        version   => '1.0.' . time(),
        );
    my $tar = Archive::Tar->new;

    $tar->add_data( 'lib/Nexus/Uploader/Test.pm',
        "package Nexus::Uploader::Test;\n1;\n" );
    $tar->write( 'Nexus-Uploader-Test.tar.gz', COMPRESS_GZIP );

    eval { $uploader->upload_file('Nexus-Uploader-Test.tar.gz'); };
    use Data::Dumper;
    print Dumper( $log->msgs() );
    ok( !$@,
        'Testing Nexus::Uploader->upload_file("Nexus-Uploader-Test.tar.gz")'
            . $@ );
    unlink 'Nexus-Uploader-Test.tar.gz';
}

# Finish the testing run
done_testing();
