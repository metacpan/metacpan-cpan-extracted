#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json decode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

# A URL-aware mock: it reads the requested URL out of the POST /crawl body and
# answers with a good page whose links are configured per URL. Robust against
# the order fmap_void completes a concurrent frontier in.
{
  package Test::C4::Site;
  use parent 'Net::Async::Crawl4AI';
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json decode_json );
  use Future;

  sub _init {
    my ( $self, $args ) = @_;
    $self->{site}    = delete $args->{site}   || {};
    $self->{delays}  = delete $args->{delays} || {};   # url => seconds before answering
    $self->{n_requests} = 0;
    $self->SUPER::_init($args);
  }

  sub n_requests { $_[0]->{n_requests} }

  sub do_request {
    my ( $self, $req, $backend ) = @_;
    $self->{n_requests}++;
    my $payload = decode_json( $req->content );
    my $url     = $payload->{urls}[0];
    my $links   = $self->{site}{$url} || [];
    my $body    = encode_json( {
      results => [ {
        status_code    => 200,
        url            => $url,
        redirected_url => $url,
        markdown       => ( 'real useful content ' x 40 ),
        links          => {
          internal => [ map { { href => $_ } } grep {  m{\Ahttps://t\.test} } @$links ],
          external => [ map { { href => $_ } } grep { !m{\Ahttps://t\.test} } @$links ],
        },
      } ],
    } );
    my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $body );
    if ( my $delay = $self->{delays}{$url} ) {
      return $self->loop->delay_future( after => $delay )->then( sub { Future->done($response) } );
    }
    return Future->done($response);
  }
}

delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};
my $loop = IO::Async::Loop->new;

sub site_crawler {
  my ( $site, %extra ) = @_;
  my $c = Test::C4::Site->new(
    base_url => 'http://localhost:9999',
    fallback => 'plain',      # one dispatch per page
    site     => $site,
    %extra,
  );
  $loop->add($c);
  return $c;
}

subtest 'deep_crawl follows links BFS, dedups, stays same-host' => sub {
  my $site = {
    'https://t.test/'  => [ 'https://t.test/b', 'https://t.test/c', 'https://ext.test/z' ],
    'https://t.test/b' => [ 'https://t.test/d', 'https://t.test/' ],   # back-link deduped
    'https://t.test/c' => [],
    'https://t.test/d' => [],
  };
  my %depth;
  my $results = site_crawler($site)->deep_crawl(
    'https://t.test/',
    max_depth => 2,
    on_page   => sub { $depth{ $_[0]->final_url } = $_[1] },
  )->get;

  is scalar @$results, 4, 'A,B,C,D crawled (ext dropped, back-link deduped)';
  is_deeply [ sort map { $_->final_url } @$results ],
    [ 'https://t.test/', 'https://t.test/b', 'https://t.test/c', 'https://t.test/d' ],
    'exactly the same-host reachable set';
  is $depth{'https://t.test/'},  0, 'start at depth 0';
  is $depth{'https://t.test/b'}, 1, 'b at depth 1';
  is $depth{'https://t.test/d'}, 2, 'd at depth 2';
  ok !( grep { $_->final_url =~ /ext\.test/ } @$results ), 'off-host not followed';
};

subtest 'deep_crawl honours max_depth and max_pages' => sub {
  my $site = {
    'https://t.test/'  => [ 'https://t.test/b', 'https://t.test/c' ],
    'https://t.test/b' => [ 'https://t.test/d' ],
    'https://t.test/c' => [],
    'https://t.test/d' => [],
  };
  my $shallow = site_crawler($site)->deep_crawl( 'https://t.test/', max_depth => 1 )->get;
  is scalar @$shallow, 3, 'depth 1: start + two children, D not reached';

  my $capped = site_crawler($site)->deep_crawl( 'https://t.test/', max_depth => 5, max_pages => 2 )->get;
  is scalar @$capped, 2, 'max_pages caps the crawl';
};

subtest 'deep_crawl same_host => 0 follows off-host links' => sub {
  my $site = {
    'https://t.test/'    => [ 'https://ext.test/z' ],
    'https://ext.test/z' => [],
  };
  my $results = site_crawler($site)->deep_crawl(
    'https://t.test/', max_depth => 1, same_host => 0,
  )->get;
  is scalar @$results, 2, 'off-host followed when same_host disabled';
  ok( ( grep { $_->final_url eq 'https://ext.test/z' } @$results ), 'external page crawled' );
};

subtest 'deep_crawl returns breadth-first order even when a later page completes first' => sub {
  my $site = {
    'https://t.test/'  => [ 'https://t.test/b', 'https://t.test/c' ],
    'https://t.test/b' => [],
    'https://t.test/c' => [],
  };
  # b is enqueued before c, but c answers immediately while b is delayed.
  my $c = site_crawler( $site, delays => { 'https://t.test/b' => 0.05 } );
  my $results = $c->deep_crawl( 'https://t.test/', max_depth => 1, concurrency => 5 )->get;
  is_deeply [ map { $_->final_url } @$results ],
    [ 'https://t.test/', 'https://t.test/b', 'https://t.test/c' ],
    'enqueue order preserved despite c completing before b';
};

subtest 'deep_crawl fires no requests beyond max_pages' => sub {
  my %site = ( 'https://t.test/' => [ map { "https://t.test/p$_" } 1 .. 50 ] );
  $site{"https://t.test/p$_"} = [] for 1 .. 50;
  my $c = site_crawler( \%site );
  my $results = $c->deep_crawl( 'https://t.test/', max_pages => 5, max_depth => 1, concurrency => 50 )->get;
  is scalar @$results, 5, 'exactly max_pages results';
  is $c->n_requests, 5, 'frontier trimmed: no requests past the budget';
};

subtest 'deep_crawl resolves to the same Result objects as a single crawl' => sub {
  my $site = { 'https://t.test/' => [] };
  my $results = site_crawler($site)->deep_crawl('https://t.test/')->get;
  is scalar @$results, 1, 'just the start page';
  isa_ok $results->[0], 'WWW::Crawl4AI::Result';
  ok $results->[0]->ok, 'start page ok';
  like $results->[0]->markdown, qr/real useful content/, 'markdown carried';
};

done_testing;
