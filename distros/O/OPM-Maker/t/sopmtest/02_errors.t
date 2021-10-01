#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OPM::Maker::Command::sopmtest';

my $dir         = File::Spec->catdir( dirname( __FILE__ ), '..', 'invalid' );
my $textfile    = File::Spec->catfile( $dir, 'test.sopm' );
my $invalid_xml = File::Spec->catfile( $dir, 'invalid.sopm' );

{
    my $error = 'Invalid .opm';

    my $exec_output = capture_stdout {
        OPM::Maker::Command::sopmtest::execute( undef, {}, [ $textfile ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = 'No file given';

    my $exec_output = capture_stdout {
        OPM::Maker::Command::sopmtest::execute( undef, {}, [ undef ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = 'does not exist';

    my $exec_output = capture_stdout {
        OPM::Maker::Command::sopmtest::execute( undef, {}, [ '/tmp/does/not/exist_yet.sopm' ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = 'Invalid .opm';

    my $exec_output = capture_stdout {
        OPM::Maker::Command::sopmtest::execute( undef, {}, [ $invalid_xml ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $invalid_xml;
}

done_testing();
