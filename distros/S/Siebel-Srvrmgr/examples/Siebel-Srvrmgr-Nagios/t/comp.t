use strict;
use warnings;
use Test::More tests => 3;
use Config;
use File::Spec;
use Test::Output;

BEGIN { use_ok('Siebel::Srvrmgr::Nagios') }

stdout_is(
    \&run_mock,
    "SCM CRITICAL - Components status is 4\n",
    'got the expected output'
);

is( ( $? >> 8 ), 2, 'comp_mon.pl returns a CRITICAL' )
  or diag( check_exec($?) );

sub run_mock {

    my $config = File::Spec->catfile( 't', 'data', 'test.xml' );
    my @args = (
        File::Spec->catfile( $Config{bin}, 'perl' ),
        'comp_mon.pl', '-w', '1', '-c', '3', '-f', $config
    );
    system(@args);

}

sub check_exec {

    my $error_code = shift;

    if ( $error_code == -1 ) {
        return "failed to execute: $!\n";
    }
    elsif ( $error_code & 127 ) {
        return sprintf(
            "child died with signal %d, %s coredump",
            (
                ( $error_code & 127 ),
                ( $error_code & 128 ) ? 'with' : 'without'
            )
        );
    }
    else {

        return sprintf "child exited with value %d\n", $? >> 8;

    }

}

