#!perl -T

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Differences;

if ($^O ne 'dos' and $^O ne 'os2' and $^O ne 'MSWin32' ) {
    plan skip_all => 'these tests are irrelevant on non-dos-ish systems';
} else {
    plan tests => 5;
}

delete @ENV{qw{PATH ENV IFS CDPATH BASH_ENV}};

my $d = 't\win-exec-dummy';
my @exe_files = qw[bla.bat foo.bat];

use_ok( 'Run::Parts' );

# Testing the perl backend
run_test_on_rp($d, 'perl');

# Testing the automatically chosen backend
run_test_on_rp($d);

sub run_test_on_rp {
    my ($d, $desc) = @_;
    my $rp = Run::Parts->new($d, $desc);

    $desc ||= 'default';

    ok($rp, 'Run::Parts->new($desc) returned non-nil');

    # Executes executable files
    eq_or_diff(''.$rp->run,
               "foobla\nfoofoo\n",
               "Returns output of ran executables ($desc)");
}

