use warnings;
use strict;
use Test::More;

BEGIN {
    if ( !eval 'use Test::Command; 1;' ) {
        $ENV{RELEASE_TESTING}
            ? die "Test::Command is required for RELEASE_TESTING"
            : plan skip_all => 'Test::Command not available';
    }
}

use System::Command;

plan tests => 2;

stdout_like(q{perl -le "print STDOUT 'STDOUT'"}, qr/STDOUT/, 'STDOUT');
stderr_like(q{perl -le "print STDERR 'STDERR'"}, qr/STDERR/, 'STDERR');

