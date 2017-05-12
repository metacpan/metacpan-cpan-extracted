#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Differences;

delete @ENV{qw{PATH ENV IFS CDPATH BASH_ENV}};

my $runpartsbin = '/bin/run-parts';
unless (-x $runpartsbin) {
    plan skip_all => "$runpartsbin not found or not executable";
    exit 0;
}

use_ok( 'Run::Parts' );

my $d = 't/basic-dummy';
my $rpd = Run::Parts->new($d, 'debian');
my $rpp = Run::Parts->new($d, 'perl');
ok($rpd, 'Run::Parts->new(debian) returned non-nil');
ok($rpp, 'Run::Parts->new(perl) returned non-nil');

# List files
eq_or_diff([$rpd->list],
           [$rpp->list],
           "Both return same list of files in array context");

eq_or_diff(''.$rpd->list,
           ''.$rpp->list,
           "Both return same list of files in string context");

# List executable files
eq_or_diff([$rpd->test],
           [$rpp->test],
           "Both return same list of executables in array context");

eq_or_diff(''.$rpd->test,
           ''.$rpp->test,
           "Both return same list of executables in string context");

# Executes executable files
eq_or_diff(''.$rpd->run,
           ''.$rpp->run,
           "Both return same output of ran executables");

done_testing();
