#! /usr/bin/env perl

use strict;
use warnings;
use LWP::UserAgent;

# plackup --no-default-middleware --e 'sub { return [200,[ "Content-Type" => "text/plain"],[ "yo" ]]}'
# NYTPROF=file=/tmp/nytprof_lwp.out perl -d:NYTProf -Ilib xt/nytprf_lwp.pl && nytprofhtml --file /tmp/nytprof_lwp.out  --out lwp

for (1..2000) {
  my $ua = LWP::UserAgent->new;
  $ua->timeout(0);
  $ua->get('http://localhost:5000/foo=bar');
}
