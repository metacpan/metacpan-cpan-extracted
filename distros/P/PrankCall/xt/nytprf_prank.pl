#! /usr/bin/env perl

use strict;
use warnings;
use Benchmark qw{cmpthese};
use PrankCall;

# plackup --no-default-middleware --e 'sub { return [200,[ "Content-Type" => "text/plain"],[ "yo" ]]}'
# NYTPROF=file=/tmp/nytprof_prank.out perl -d:NYTProf -Ilib xt/nytprf_prank.pl && nytprofhtml --file /tmp/nytprof_prank.out  --out prank

for (1..2000) {
  my $prank = PrankCall->new(host => 'http://localhost', port => 5000);
  $prank->get(path => '/', params => {neat => 'blah'});
}
