use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::Oozie");
}

SKIP: {
    skip "No OOZIE_URL in environment", 1 if ! $ENV{OOZIE_URL};

    my $oozie = Net::Hadoop::Oozie->new;
    my $build = $oozie->build_version;
    my $status = $oozie->admin('status');

    ok( $build =~ /^4\./, 'Got some version' );
    ok( $status, 'Got admin/status' );
    diag( "admin/status: " .  Dumper $status );

    ok( 1, 'Rest of the tests are not yet implemented ...');
}

done_testing();
