#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

my $run = run_perl(<<'END_SCRIPT');
print "out line\n";
print STDERR "err line\n";
exit 3;
END_SCRIPT

is( $run->{stdout}, "out line\n", 'standard output of the child is captured' );
is( $run->{stderr}, "err line\n", 'standard error of the child is captured apart' );
is( $run->{exit},   3,            'exit code of the child is captured' );

my $filtered = run_perl(<<'END_SCRIPT');
use Podlite;
=head1 Title

print "after\n";
END_SCRIPT

is( $filtered->{stdout}, "after\n", 'the child finds the module under test' );
is( $filtered->{exit},   0,         'the filtered child exits cleanly' );

done_testing();
