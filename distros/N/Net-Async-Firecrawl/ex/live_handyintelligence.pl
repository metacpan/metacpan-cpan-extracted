#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IO::Async::Loop;
use Net::Async::Firecrawl;

my $loop = IO::Async::Loop->new;
my $fc = Net::Async::Firecrawl->new(
  base_url      => 'http://10.5.10.1:3002',
  poll_interval => 2,
);
$loop->add($fc);

say "=== scrape handyintelligence.com ===";
my $doc = $fc->scrape(
  url     => 'https://handyintelligence.com',
  formats => ['markdown'],
)->get;
say "title: ", $doc->{metadata}{title} // '(none)';
say "status: ", $doc->{metadata}{statusCode} // '?';
say "markdown length: ", length($doc->{markdown} // '');
say "first 400 chars:";
say substr($doc->{markdown} // '', 0, 400);

say "\n=== map handyintelligence.com ===";
my $links = $fc->map( url => 'https://handyintelligence.com', limit => 50 )->get;
say "found ", scalar(@$links), " links";
say "  - ", ($_->{url} // $_) for @{$links}[ 0 .. ($#$links > 9 ? 9 : $#$links) ];

say "\n=== crawl_and_collect (limit 5) ===";
my $crawl = $fc->crawl_and_collect(
  url   => 'https://handyintelligence.com',
  limit => 5,
  scrapeOptions => { formats => ['markdown'] },
)->get;
say "status: $crawl->{status}";
say "pages: ", scalar @{ $crawl->{data} || [] };
for my $p (@{ $crawl->{data} }) {
  my $url = $p->{metadata}{sourceURL} // $p->{metadata}{url} // '?';
  my $len = length($p->{markdown} // '');
  say "  - $url  (md=${len} chars)";
}
