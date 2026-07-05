#!/usr/bin/env perl
# Demonstrate the programmatic API: analyse a CPAN dist by name and
# render JSON output, then inspect individual check results.

use strict;
use warnings;

use lib '../lib';
use Test::CPAN::Health;

my $dist_name = shift @ARGV // 'LWP-UserAgent';

print "Analysing $dist_name ...\n";

my $health = Test::CPAN::Health->new(
	dist	   => $dist_name,
	format	 => 'json',
	no_network => 0,
	no_cover   => 1,	   # skip slow Devel::Cover run
	min_score  => 70,
);

my $report = $health->analyse;

# Print JSON report
print $health->report_to($report), "\n";

# Inspect individual results programmatically
printf "\nSummary: %d/100\n", $report->overall_score;
printf "Passed: %d  Warned: %d  Failed: %d  Skipped: %d\n",
	$report->pass_count, $report->warn_count,
	$report->fail_count, $report->skip_count;

# Show only failing checks
my @failures = grep { $_->status eq 'fail' } @{ $report->results };
if (@failures) {
	print "\nFailing checks:\n";
	for my $r (@failures) {
		printf "  %s: %s\n", $r->data->{name} // $r->check_id, $r->summary;
	}
}

exit($report->overall_score < 70 ? 1 : 0);
