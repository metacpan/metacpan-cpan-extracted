#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use Capture::Tiny qw(capture_stdout);

use File::Spec;
use File::Basename;
use File::Temp qw(tempdir);

use_ok 'OTRS::OPM::Maker::Command::sopmtest';

my $dir         = File::Spec->catdir( dirname( __FILE__ ), '..', 'invalid' );
my $textfile    = File::Spec->catfile( $dir, 'test.sopm' );
my $invalid_xml = File::Spec->catfile( $dir, 'invalid.sopm' );

{
    my $error = 'Cannot parse .sopm:';

    my $exec_output = capture_stdout {
        OTRS::OPM::Maker::Command::sopmtest::execute( undef, {}, [ $textfile ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = 'Cannot parse .sopm:';

    my $exec_output = capture_stdout {
        OTRS::OPM::Maker::Command::sopmtest::execute( undef, {}, [ undef ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = 'Cannot parse .sopm:';

    my $exec_output = capture_stdout {
        OTRS::OPM::Maker::Command::sopmtest::execute( undef, {}, [ '/tmp/does/not/exist_yet.sopm' ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $textfile;
}

{
    my $error = '.sopm is not valid:';

    my $exec_output = capture_stdout {
        OTRS::OPM::Maker::Command::sopmtest::execute( undef, {}, [ $invalid_xml ] );
    };

    #diag $exec_output;

    like_string $exec_output, qr/$error/, $invalid_xml;
}

done_testing();
