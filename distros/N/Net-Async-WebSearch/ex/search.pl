#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use IO::Async::Loop;
use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::DuckDuckGo;
use Net::Async::WebSearch::Provider::SearxNG;
use Net::Async::WebSearch::Provider::Serper;
use Net::Async::WebSearch::Provider::Brave;

my $query = shift @ARGV || 'handyintelligence';

my $loop = IO::Async::Loop->new;

my @providers = ( Net::Async::WebSearch::Provider::DuckDuckGo->new );

push @providers, Net::Async::WebSearch::Provider::SearxNG->new(
  endpoint => $ENV{SEARXNG_ENDPOINT},
) if $ENV{SEARXNG_ENDPOINT};

push @providers, Net::Async::WebSearch::Provider::Serper->new(
  api_key => $ENV{SERPER_API_KEY},
) if $ENV{SERPER_API_KEY};

push @providers, Net::Async::WebSearch::Provider::Brave->new(
  api_key => $ENV{BRAVE_API_KEY},
) if $ENV{BRAVE_API_KEY};

my $ws = Net::Async::WebSearch->new( providers => \@providers );
$loop->add($ws);

# Stream mode: print each result as soon as any provider returns.
$ws->search_stream(
  query     => $query,
  limit     => 20,
  on_result => sub {
    my $r = shift;
    say sprintf '[%s #%d] %s', $r->provider, $r->rank, $r->title // '(no title)';
    say '  ', $r->url;
    say '  ', $r->snippet if $r->snippet;
  },
  on_provider_error => sub {
    my ( $name, $err ) = @_;
    warn "[$name] $err\n";
  },
)->get;
