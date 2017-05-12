#!/usr/bin/perl 

use strict;
use warnings;
use Stream::Aggregate;
use List::Util qw(sum);
use Test::More qw(no_plan);
use YAML;

my $finished = 0;

END { ok($finished, 'finished') }

my $aconfig = Load(<<'END_ACONFIG');
strict:                 1
debug:                  0
item_name:              $item
max_stats_to_keep:      500
context:                $item->{domain}
context2columns:        return (domain => $current_context[0])
ephemeral:
  # 
  # The only persistent unstructured place to store data from 
  # one row to the next is $ps->{heap}.   $ps->{heap} 
  # is per-context, but that's okay for our usage.
  #
  is_different: |
    my $old = $ps->{heap}{last_item};
    $ps->{heap}{last_item} = $item;
    return 1 unless $old;
    return 0 if $old->{url} eq $item->{url};
    return 1;
sum:
  unique_urls:          $column_is_different
mean:                   
  avg_url_length:       length($item->{url})
finalize_result: |
  # we don't want the roll-up context of all domains
  $suppress_result = 1 unless $row->{domain};
END_ACONFIG

my $ag = generate_aggregation_func($aconfig, { 
	name	=> 'Aggregate URL data'
});

my @results;

for $_ (<DATA>, undef) {
	# we'll parse the input here
	my $item;
	if ($_) {
		chomp;
		next if /^$/;
		next if /^#/;
		die "'$_'" unless m{^\w+:\/\/([^/]+)(?:/.*)?};
		$item = {
			domain	=> $1,
			url	=> $_,
		};
	} else {
		$item = undef;
	}
	for my $result ($ag->($item)) {
		push(@results, $result);
	}
}

# print YAML::Dump(\@results);

my ($abba, $sharnoff, $google, $end) = @results;

is($abba->{unique_urls}, 3, "url count for abba");
is($sharnoff->{unique_urls}, 15, "url count for sharnoff");
is($google->{unique_urls}, 1, "url count for google");
is($abba->{domain}, "abba.com", "abba is abba");
is($sharnoff->{domain}, "dave.sharnoff.org", "sharnoff is sharnoff");
is($google->{domain}, "google.com", "google is google");
is($end, undef, "only three");


$finished = 1;

__DATA__
http://abba.com/history.html
http://abba.com/index.html
http://abba.com/upcoming_concerts.html
http://dave.sharnoff.org/bepress-detail.html
http://dave.sharnoff.org/bepress-detail.pdf
http://dave.sharnoff.org/bepress-detail.txt
http://dave.sharnoff.org/idiom-detail.html
http://dave.sharnoff.org/idiom-detail.pdf
http://dave.sharnoff.org/idiom-detail.txt
http://dave.sharnoff.org/resume/index.html
http://dave.sharnoff.org/resume.html
http://dave.sharnoff.org/resume.html
http://dave.sharnoff.org/resume.html
http://dave.sharnoff.org/resume.pdf
http://dave.sharnoff.org/resume.pdf
http://dave.sharnoff.org/resume.pdf
http://dave.sharnoff.org/searchme-detail.html
http://dave.sharnoff.org/searchme-detail.pdf
http://dave.sharnoff.org/searchme-detail.txt
http://dave.sharnoff.org/yahoo-detail.html
http://dave.sharnoff.org/yahoo-detail.pdf
http://dave.sharnoff.org/yahoo-detail.txt
http://google.com/index.html
