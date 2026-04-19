#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;

use Net::Async::WebSearch;

# Live integration tests against real search engines.
# Each subtest runs only if its TEST_WEBSEARCH_* env vars are set.
# To run one specific engine:
#   TEST_WEBSEARCH_BRAVE_API_KEY=xxx prove -lv t/50-live.t
#
# Conventions:
#   - Keyless engines (DuckDuckGo, Reddit) are gated by TEST_WEBSEARCH_LIVE=1
#     so a casual `prove -l t/` still doesn't hit the public web.
#   - Paid engines are gated by their API key env var being present.
#   - Queries are short, generic, and ask for few results to keep costs low.

unless ( $ENV{TEST_WEBSEARCH_LIVE} || grep { /^TEST_WEBSEARCH_/ && $ENV{$_} } keys %ENV ) {
  plan skip_all => "set TEST_WEBSEARCH_LIVE=1 or any TEST_WEBSEARCH_* var to run live tests";
}

my $QUERY = 'perl programming language';

sub run_one {
  my ( $name, $provider, %opts ) = @_;
  my $loop = IO::Async::Loop->new;
  my $ws = Net::Async::WebSearch->new( providers => [ $provider ] );
  $loop->add($ws);

  my $f = $ws->search(
    query => $QUERY,
    limit => $opts{limit} // 3,
    per_provider_limit => $opts{limit} // 3,
  );

  my $out = eval { $f->get };
  if ( my $e = $@ ) {
    fail "$name: search threw: $e";
    return;
  }
  if ( @{ $out->{errors} } ) {
    my $err = $out->{errors}[0]{error};
    fail "$name: provider error: $err";
    return;
  }
  my @r = @{ $out->{results} };
  ok scalar @r, "$name: got ".scalar(@r)." result(s)"
    or return;
  ok defined $r[0]->url  && length $r[0]->url,   "$name: first result has url";
  ok defined $r[0]->title && length $r[0]->title,"$name: first result has title";
  note sprintf "  [%s] %s — %s", $r[0]->provider, ($r[0]->title // ''), ($r[0]->url // '');
}

subtest 'DuckDuckGo (HTML, keyless)' => sub {
  plan skip_all => 'set TEST_WEBSEARCH_LIVE=1 to run keyless live tests'
    unless $ENV{TEST_WEBSEARCH_LIVE};
  require Net::Async::WebSearch::Provider::DuckDuckGo;
  run_one( 'duckduckgo',
    Net::Async::WebSearch::Provider::DuckDuckGo->new,
  );
};

subtest 'Reddit (public JSON, keyless)' => sub {
  plan skip_all => 'set TEST_WEBSEARCH_LIVE=1 to run keyless live tests'
    unless $ENV{TEST_WEBSEARCH_LIVE};
  require Net::Async::WebSearch::Provider::Reddit;
  run_one( 'reddit',
    Net::Async::WebSearch::Provider::Reddit->new(
      sort => 'relevance',
    ),
  );
};

subtest 'SearxNG' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_SEARXNG_ENDPOINT'
    unless $ENV{TEST_WEBSEARCH_SEARXNG_ENDPOINT};
  require Net::Async::WebSearch::Provider::SearxNG;
  run_one( 'searxng',
    Net::Async::WebSearch::Provider::SearxNG->new(
      endpoint => $ENV{TEST_WEBSEARCH_SEARXNG_ENDPOINT},
      ( $ENV{TEST_WEBSEARCH_SEARXNG_API_KEY}
          ? ( api_key => $ENV{TEST_WEBSEARCH_SEARXNG_API_KEY} )
          : () ),
    ),
  );
};

subtest 'Brave Search API' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_BRAVE_API_KEY'
    unless $ENV{TEST_WEBSEARCH_BRAVE_API_KEY};
  require Net::Async::WebSearch::Provider::Brave;
  run_one( 'brave',
    Net::Async::WebSearch::Provider::Brave->new(
      api_key => $ENV{TEST_WEBSEARCH_BRAVE_API_KEY},
    ),
  );
};

subtest 'Serper.dev' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_SERPER_API_KEY'
    unless $ENV{TEST_WEBSEARCH_SERPER_API_KEY};
  require Net::Async::WebSearch::Provider::Serper;
  run_one( 'serper',
    Net::Async::WebSearch::Provider::Serper->new(
      api_key => $ENV{TEST_WEBSEARCH_SERPER_API_KEY},
    ),
  );
};

subtest 'Google Programmable Search' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_GOOGLE_API_KEY + TEST_WEBSEARCH_GOOGLE_CX'
    unless $ENV{TEST_WEBSEARCH_GOOGLE_API_KEY}
        && $ENV{TEST_WEBSEARCH_GOOGLE_CX};
  require Net::Async::WebSearch::Provider::Google;
  run_one( 'google',
    Net::Async::WebSearch::Provider::Google->new(
      api_key => $ENV{TEST_WEBSEARCH_GOOGLE_API_KEY},
      cx      => $ENV{TEST_WEBSEARCH_GOOGLE_CX},
    ),
  );
};

subtest 'Yandex Search API' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_YANDEX_API_KEY + TEST_WEBSEARCH_YANDEX_FOLDERID'
    unless $ENV{TEST_WEBSEARCH_YANDEX_API_KEY}
        && $ENV{TEST_WEBSEARCH_YANDEX_FOLDERID};
  require Net::Async::WebSearch::Provider::Yandex;
  run_one( 'yandex',
    Net::Async::WebSearch::Provider::Yandex->new(
      api_key  => $ENV{TEST_WEBSEARCH_YANDEX_API_KEY},
      folderid => $ENV{TEST_WEBSEARCH_YANDEX_FOLDERID},
    ),
  );
};

subtest 'Reddit OAuth (client_credentials)' => sub {
  plan skip_all => 'need TEST_WEBSEARCH_REDDIT_CLIENT_ID + TEST_WEBSEARCH_REDDIT_CLIENT_SECRET'
    unless $ENV{TEST_WEBSEARCH_REDDIT_CLIENT_ID}
        && defined $ENV{TEST_WEBSEARCH_REDDIT_CLIENT_SECRET};
  require Net::Async::WebSearch::Provider::Reddit::OAuth;
  my $ua = $ENV{TEST_WEBSEARCH_REDDIT_USER_AGENT}
        // 'net-async-websearch-tests/0.001 (live test)';
  run_one( 'reddit-oauth',
    Net::Async::WebSearch::Provider::Reddit::OAuth->new(
      client_id     => $ENV{TEST_WEBSEARCH_REDDIT_CLIENT_ID},
      client_secret => $ENV{TEST_WEBSEARCH_REDDIT_CLIENT_SECRET},
      user_agent    => $ua,
    ),
  );
};

subtest 'aggregation + fetch (uses whatever engines are configured)' => sub {
  plan skip_all => 'set TEST_WEBSEARCH_LIVE=1 to run combined/fetch test'
    unless $ENV{TEST_WEBSEARCH_LIVE};
  my $loop = IO::Async::Loop->new;
  my @provs;
  if ( $ENV{TEST_WEBSEARCH_BRAVE_API_KEY} ) {
    require Net::Async::WebSearch::Provider::Brave;
    push @provs, Net::Async::WebSearch::Provider::Brave->new(
      api_key => $ENV{TEST_WEBSEARCH_BRAVE_API_KEY},
    );
  }
  require Net::Async::WebSearch::Provider::DuckDuckGo;
  push @provs, Net::Async::WebSearch::Provider::DuckDuckGo->new;

  my $ws = Net::Async::WebSearch->new( providers => \@provs );
  $loop->add($ws);

  my $out = $ws->search(
    query            => $QUERY,
    limit            => 5,
    per_provider_limit => 5,
    fetch            => 2,
    fetch_timeout    => 15,
    fetch_max_bytes  => 200_000,
  )->get;

  ok scalar @{ $out->{results} }, 'some merged results';
  is $out->{stats}{fetched} // 0, 2, '2 pages fetched';
  my @fetched = grep { $_->fetched } @{ $out->{results} };
  ok( ( grep { ($_->fetched->{ok}//0) == 1 } @fetched ),
      'at least one fetched body came back ok' );
};

done_testing;
