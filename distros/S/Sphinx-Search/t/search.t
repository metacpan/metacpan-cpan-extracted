#! /usr/bin/perl

# Copyright 2007 Jon Schutz, all rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License.

# Main functional test for Sphinx::Search
# Loads data into mysql, runs indexer, starts searchd, validates results.

use strict;
use warnings;

use DBI;
use Test::More;
use File::SearchPath qw/searchpath/;
use Path::Class;
use Sphinx::Search;
use Socket;
use Data::Dumper;
use List::MoreUtils qw/all/;

use lib qw(t/testlib testlib);

use TestDB;


my $testdb = TestDB->new();

if (my $msg = $testdb->preflight) {
    plan skip_all => $msg;
}

unless ($testdb->run_indexer()) {
    plan skip_all => "Failed to run indexer; skipping tests.";
}

unless ($testdb->run_searchd()) {
    plan skip_all => "Failed to run searchd; skipping tests.";
}

# Everything is in place; run the tests
plan tests => 117;

my $logger;

#use Log::Log4perl qw/:easy/;
#Log::Log4perl->easy_init($DEBUG);
#$logger = Log::Log4perl->get_logger();

my $sphinx = Sphinx::Search->new({ port => $testdb->searchd_port, log => $logger, debug => 1 });
ok($sphinx, "Constructor");

run_all_tests();
$sphinx->SetSortMode(SPH_SORT_RELEVANCE)
    ->SetRankingMode(SPH_RANK_PROXIMITY_BM25)
    ->SetFieldWeights({});
$sphinx->SetConnectTimeout(2);
run_all_tests();


sub run_all_tests {
# Basic test on 'a'
my $results = $sphinx->Query("a");
ok($results, "Results for 'a'");

print $sphinx->GetLastError unless $results;
ok($results->{total_found} == 4, "total_found for 'a'");
ok($results->{total} == 4, "total for 'a'");
ok(@{$results->{matches}} == 4, "matches for 'a'");
is_deeply($results->{'words'}, 
	  {
	      'a' => {
		  'hits' => 4,
		  'docs' => 4
		  }
	  },
	  "words for 'a'");
is_deeply($results->{'fields'}, [ qw/field1 field2/ ], "fields for 'a'");
is_deeply($results->{'attrs'}, { attr1 => 1, lat => 5, long => 5, stringattr => 7 }, "attributes for 'a'");
my $weight = $results->{matches}[0]{weight};
ok((all { $_->{weight} == $weight } @{$results->{matches}}), "weights for 'a'");

# Rank order test on 'bb'
$sphinx->SetSortMode(SPH_SORT_RELEVANCE);
$results = $sphinx->Query("bb");
ok($results, "Results for 'bb'");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 5, "matches for 'bb'");
my $order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless $results->{matches}->[$_ - 1]->{weight} >= $results->{matches}->[$_]->{weight};
}
ok($order_ok, 'SPH_SORT_RELEVANCE');

# Phrase on "ccc dddd"
$sphinx->SetSortMode(SPH_SORT_ATTR_ASC, "attr1");
$results = $sphinx->Query('"ccc dddd"');
ok($results, "Results for '\"ccc dddd\"'");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 3, "matches for '\"ccc dddd\"'");
$order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless $results->{matches}->[$_ - 1]->{attr1} <= $results->{matches}->[$_]->{attr1};
}
ok($order_ok, 'SPH_SORT_ATTR_ASC');

# Boolean on "bb ccc"
$sphinx->SetSortMode(SPH_SORT_ATTR_DESC, "attr1");
$results = $sphinx->Query("bb ccc");
ok($results, "Results for 'bb ccc'");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 4, "matches for 'bb ccc'");
$order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless $results->{matches}->[$_ - 1]->{attr1} >= $results->{matches}->[$_]->{attr1};
}
ok($order_ok, 'SPH_SORT_ATTR_DESC');

# Any on "bb ccc"
$sphinx->SetSortMode(SPH_SORT_EXTENDED, '@relevance DESC, attr1 ASC');
$results = $sphinx->Query("bb | ccc");
ok($results, "Results for 'bb ccc' ANY");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 5, "matches for 'bb ccc' ANY");
$order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless
	($results->{matches}->[$_]->{weight} <=> $results->{matches}->[$_-1]->{weight} || 
	 $results->{matches}->[$_ - 1]->{attr1} <=> $results->{matches}->[$_]->{attr1}) <= 0;
}
ok($order_ok, 'SPH_SORT_EXTENDED');

$sphinx->SetSortMode(SPH_SORT_RELEVANCE)
    ->SetLimits(0,2);
$results = $sphinx->Query("bb");
ok($results, "Results for 'bb' with limit");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 2, "matches for 'bb'");

# Extended on "bb ccc"
$sphinx->SetLimits(0,20);
$results = $sphinx->Query('@field1 bb @field2 ccc');
ok($results, "Results for 'bb ccc' EXTENDED");
print $sphinx->GetLastError unless $results;
ok(@{$results->{matches}} == 2, "matches for 'bb ccc' EXTENDED");
ok($results->{matches}->[0]->{doc} =~ m/^(?:4|5)$/ &&
   $results->{matches}->[1]->{doc} =~ m/^(?:4|5)$/, "matched docs for 'bb ccc' EXTENDED");

# SetIndexWeights
$sphinx->SetSortMode(SPH_SORT_RELEVANCE)
    ->SetIndexWeights({ test_jjs_index => 2});
$results = $sphinx->Query("bb | ccc");
ok($results, "Results for 'bb | ccc'");
print $sphinx->GetLastError unless $results;
$order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless $results->{matches}->[$_ - 1]->{weight} >= $results->{matches}->[$_]->{weight} && $results->{matches}->[$_]->{weight} > 1;
}
ok($order_ok, 'Weighted index');

# SetFieldWeights
$sphinx->SetSortMode(SPH_SORT_RELEVANCE)
    ->SetFieldWeights({ field2 => 2, field1 => 10 });
$results = $sphinx->Query("bb | ccc");
ok($results, "Results for 'bb | ccc'");
print $sphinx->GetLastError unless $results;
$order_ok = 1;
for (1 .. @{$results->{matches}} - 1) {
    $order_ok = 0, last unless $results->{matches}->[$_ - 1]->{weight} >= $results->{matches}->[$_]->{weight} && $results->{matches}->[$_]->{weight} > 1;
}
ok($order_ok, 'Field-weighted relevance');

# Excerpts
$results = $sphinx->BuildExcerpts([ "bb bb ccc dddd", "bb ccc dddd" ],
		       "test_jjs_index",
		       "ccc dddd");
is_deeply($results, [ 'bb bb <b>ccc</b> <b>dddd</b>', 'bb <b>ccc</b> <b>dddd</b>' ],
	  "Excerpts");
# Excerpts UTF8
$results = $sphinx->BuildExcerpts([ "\x{65e5}\x{672c}\x{8a9e}" ],
		       "test_jjs_index",
		       "\x{65e5}\x{672c}\x{8a9e}");
is_deeply($results, [ "<b>\x{65e5}\x{672c}\x{8a9e}</b>" ], "UTF8 Excerpts");


# Keywords
$results = $sphinx->BuildKeywords("bb-dddd",  "test_jjs_index", 1);
is_deeply($results, [
		     {
			 'hits' => 8,
			 'docs' => 5,
			 'tokenized' => 'bb',
			 'normalized' => 'bb'
			 },
		     {
			 'hits' => 3,
			 'docs' => 3,
			 'tokenized' => 'dddd',
			 'normalized' => 'dddd'
			 }
		     ],
	  "Keywords");

# Keywords UTF8
$results = $sphinx->BuildKeywords("\x{65e5}\x{672c}\x{8a9e}",  "test_jjs_index", 1);
is_deeply($results, [
          {
            'hits' => 1,
            'docs' => 1,
            'tokenized' => "\x{65e5}\x{672c}\x{8a9e}",
            'normalized' => "\x{65e5}\x{672c}\x{8a9e}"
          }
	  ]);


# EscapeString
$results = $sphinx->EscapeString(q{$#abcde!@%});
is($results, '\$\#abcde\!\@\%', "EscapeString");

# Update
$sphinx->UpdateAttributes("test_jjs_index", [ qw/attr1/ ], 
			  { 
			      1 => [ 10 ],
			      2 => [ 10 ],
			      3 => [ 20 ],
			      4 => [ 20 ],
			  });
# Verify update with grouped search
$sphinx->SetSortMode(SPH_SORT_RELEVANCE)
    ->SetGroupBy("attr1", SPH_GROUPBY_ATTR);
$results = $sphinx->Query("bb");
ok($results, "Results for 'bb'");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 3, "Update attributes, grouping");

# Attribute filters
$sphinx->ResetGroupBy
    ->SetFilter("attr1", [ 10 ]);
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 2, "Filter");

# Attribute exclude
$sphinx->ResetFilters->SetFilter("attr1", [ 10 ], 1);
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 3, "Filter exclude");

# String filter
$sphinx->ResetFilters
    ->SetFilterString("stringattr", 'new string attribute');
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 1, "String Filter");

# Range filters
$sphinx->ResetFilters->SetFilterRange("attr1", 2, 11);
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 3, "Range filter");

# Range filters exclude
$sphinx->ResetFilters->SetFilterRange("attr1", 2, 11, 1);
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 2, "Range filter exclude");

# Float range filters
$sphinx->ResetFilters->SetFilterFloatRange("lat", 0.2, 0.4);
$results = $sphinx->Query("a");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 3, "Float range filter");

# Float range filters exclude
$sphinx->ResetFilters->SetFilterFloatRange("lat", 0.2, 0.4, 1);
$results = $sphinx->Query("a");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 1, "Float range filter exclude");

# ID Range
$sphinx->ResetFilters->SetIDRange(2, 4);
$results = $sphinx->Query("bb");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 3, "ID range");

# Geodistance
$sphinx->SetGeoAnchor('lat', 'long', 0.4, 0.4)
    ->SetSortMode(SPH_SORT_EXTENDED, '@geodist desc')
        ->SetFilterFloatRange('@geodist', 0,  1934127);
$results = $sphinx->Query('a');
print $sphinx->GetLastError unless $results;
ok($results->{total} == 2, "SetGeoAnchor");


# UTF-8 test
$sphinx->ResetFilters->SetSortMode(SPH_SORT_RELEVANCE)->SetIDRange(0, 0xFFFFFFFF);
$results = $sphinx->Query("bb\x{2122}");
ok($results, "UTF-8");
print $sphinx->GetLastError unless $results;
ok($results->{total} == 5, "UTF-8 results count");
$results = $sphinx->Query("\x{65e5}\x{672c}\x{8a9e}");
ok($results->{total} == 1, "UTF-8 japanese results count");
ok($results->{words}->{"\x{65e5}\x{672c}\x{8a9e}"}, "UTF-8 japanese match");

# SetQueryFlag
$sphinx->SetQueryFlag(SPH_QF_REVERSE_SCAN, 1);
$results = $sphinx->Query("");
ok($results, "SetQueryFlag"); # not sure what can be tested here

# Batch interface
$sphinx->AddQuery("ccc");
$sphinx->AddQuery("dddd");
$results = $sphinx->RunQueries;
ok(@$results == 2, "Results for batch query");

# Batch interface with error
$sphinx->AddQuery("ccc @\@dddd");
$sphinx->AddQuery("dddd");
$results = $sphinx->RunQueries;
ok(@$results == 2, "Results for batch query with error");
ok($results->[0]->{error}, "Error result");
			       
# 64 bit ID
# Check for id64 support
SKIP: {
    my $searchd = $testdb->searchd;
    my $sig = `$searchd`;
    skip "searchd not compiled with --enable-id64: 64 bit IDs not supported", 3 unless $sig =~ m/id64/;
    $sphinx->ResetFilters
	->SetIDRange(0, '18446744073709551615')
	->SetSortMode(SPH_SORT_RELEVANCE);
    $results = $sphinx->Query("xx");
#print Dumper($results);
#skip "64 bit IDs not supported", 3 if !$results && $sphinx->GetLastError =~ m/zero-sized/;
    ok($results, "Results for 'xx'");
    print $sphinx->GetLastError unless $results;
    ok($results->{total} == 1, "ID 64 results count");
    is($results->{matches}->[0]->{doc}, '9223372036854775807', "ID 64");
}

# Status
my $status = $sphinx->Status();
ok( $status->{connections} > 0, "Status");

ok(persistent_connection_test($sphinx), "persistent connection");
}

sub persistent_connection_test {
  my $sph = shift;

  unless ($sph->Open()) {
      warn "Open() failed";
      return 0;
  }
  $sph->ResetFilters
    ->SetSortMode(SPH_SORT_RELEVANCE);
  for (1..10) {
    my $results = $sphinx->Query("bb") or die "No results";
    return 0 unless $results->{total} == 5;
  }
  unless ($sph->Close()) {
      warn "Close() failed";
      return 0;
  }

  return 1;
}

