#!/usr/bin/perl -w

BEGIN {
    open(LOG, '>logfile') || die "Can't open logfile: $!";
    print LOG "# The first line\n";
    close LOG;
}

use Test::AtRuntime 'logfile';
use Test::More;

sub foo {
    TEST {
        pass('foo');
    }
}

sub bar {
    TEST {
        pass('bar');
    }
}


foo();
bar();


print "1..6\n";
ok( open(LOG, "logfile"), 'logfile opened' ) || diag "Can't open logfile";
is( <LOG>, "# The first line\n", 'Appending to logfile' );
like( <LOG>, qr/^ok .* foo$/,  'Tests appear in logfile' );
close LOG;

ok( open(LOG, "logfile"), 'logfile opened' ) || diag "Can't open logfile";
print <LOG>;
close LOG;

1 while unlink 'logfile';
