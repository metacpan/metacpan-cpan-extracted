#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Temp ();
use Path::Util qw(
                     basename
             );

my $tempdir = File::Temp::tempdir();

subtest basename => sub {
    is(basename("$tempdir/foo"), "foo");
};

DONE_TESTING:
done_testing;
