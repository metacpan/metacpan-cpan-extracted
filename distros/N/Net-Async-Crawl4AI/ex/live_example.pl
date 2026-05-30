#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use IO::Async::Loop;
use Net::Async::Crawl4AI;

# Point at a running Crawl4AI Docker container (see WWW::Crawl4AI's
# examples/docker-compose.yml). Override with CRAWL4AI_URL.
my $loop    = IO::Async::Loop->new;
my $crawler = Net::Async::Crawl4AI->new(
  base_url         => $ENV{CRAWL4AI_URL} || 'http://localhost:11235',
  cloakbrowser_url => $ENV{CLOAKBROWSER_CDP_URL},    # optional
  poll_interval    => 2,
);
$loop->add($crawler);

say "=== health ===";
say $crawler->health->get ? "crawl4ai: reachable" : "crawl4ai: DOWN";
say "chain: " . join( ' -> ', @{ $crawler->available_backends } );

my $url = shift @ARGV || 'https://example.com';

say "\n=== async strategy chain: $url ===";
my $result = $crawler->markdown($url)->get;
say "ok:       " . ( $result->ok ? 'yes' : 'no' );
say "backend:  " . ( $result->backend    // '(none)' );
say "final:    " . ( $result->final_url  // '(none)' );
say "why:      " . ( $result->why_failed // '-' );
say "md chars: " . length( $result->markdown // '' );
say "attempts: " . $result->attempts_json;
say "\nfirst 400 chars:\n" . substr( $result->markdown // '', 0, 400 );

say "\n=== async crawl job: $url ===";
my $job = $crawler->crawl_job_and_wait($url)->get;
say "status: $job->{status}";
say "pages:  " . scalar @{ $job->{pages} || [] };
