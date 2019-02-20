#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Capture::Tiny qw(capture_stderr);
use File::Basename;

use lib dirname(__FILE__).'/lib';

use MojoX::GlobalEvents;

throws_ok { MojoX::GlobalEvents->init } qr/ERROR: Missing namespace/, 'init failed for missing namespace';

MojoX::GlobalEvents->init('GlobalEvents::Test');

{
    my $msg = '';
    my $success = on 'test1' => sub { $msg = __PACKAGE__ };
    publish 'test1';

    is $success, 1;
    is $msg, 'main';
}

{
    my $stderr = capture_stderr {
        publish 'ge_test_stderr';
    };

    is $stderr, 'GlobalEvents::Test::Stderr';
}

{
    my $stderr = capture_stderr {
        publish 'ge_test_stderr_tee';
    };

    is $stderr, 'GlobalEvents::Test::Stderr::Tee';
}

{
    my $msg = '';
    my $success = on 'ge_test_stderr' => sub { $msg = __PACKAGE__ };
    is $success, 1;

    my $stderr = capture_stderr {
        publish 'ge_test_stderr';
    };

    is $stderr, 'GlobalEvents::Test::Stderr';
    is $msg, 'main';
}

{
    my $success = on();
    is $success, undef;
}

{
    my $success = on( {} );
    is $success, undef;
}

{
    my $success = on( [] );
    is $success, undef;
}

{
    my $success = on( 'test' );
    is $success, undef;
}

{
    my $success = on( 'test' => {} );
    is $success, undef;
}

{
    publish 'does_not_exist';
}


done_testing();
