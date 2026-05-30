#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

# Subclass that answers each crawl_once dispatch from a scripted response table
# (one entry per strategy run) instead of going over the network.
{
  package Test::C4::Scripted;
  use parent 'Net::Async::Crawl4AI';
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json );
  use Future;

  sub _init {
    my ( $self, $args ) = @_;
    $self->{script} = delete $args->{script} || [];
    $self->{log}    = [];
    $self->SUPER::_init($args);
  }

  sub do_request {
    my ( $self, $req, $backend ) = @_;
    push @{ $self->{log} }, { method => $req->method, uri => $req->uri . '', backend => $backend };
    my $step = shift @{ $self->{script} }
      or return Future->fail("script exhausted for " . $req->method . ' ' . $req->uri);
    my $body = ref $step->{body} ? encode_json( $step->{body} ) : ( $step->{body} // '' );
    return Future->done(
      HTTP::Response->new(
        $step->{code} // 200, $step->{message} // 'OK',
        [ 'Content-Type' => 'application/json' ], $body,
      ),
    );
  }

  sub log { $_[0]->{log} }
}

# Clear env so the default chain is exactly plain -> browser -> stealth.
delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};

my $loop = IO::Async::Loop->new;

sub page {
  my ( %p ) = @_;
  return { results => [ { %p } ] };
}

my $thin    = page( status_code => 200, markdown => 'too short' );
my $blocked = page( status_code => 403, markdown => ( 'Access Denied ' x 50 ) );
my $good    = page( status_code => 200, markdown => ( 'real useful content ' x 40 ),
                    metadata => { title => 'OK' } );

sub mk {
  my ( @script ) = @_;
  my $c = Test::C4::Scripted->new( base_url => 'http://localhost:9999', script => [ @script ] );
  $loop->add($c);
  return $c;
}

subtest 'async chain escalates plain -> browser -> stealth, stops at first good' => sub {
  my $c = mk(
    { body => $thin },      # plain
    { body => $blocked },   # browser
    { body => $good },      # stealth
  );
  my $r = $c->markdown('https://example.com')->get;

  isa_ok $r, 'WWW::Crawl4AI::Result';
  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_stealth', 'stealth won';
  is $r->cost_class, 'stealth', 'cost class reported';
  is $r->attempt_count, 3, 'three attempts';
  is $r->attempts->[0]->why_failed, 'thin_content', 'plain failed thin';
  is $r->attempts->[1]->why_failed, 'bot_wall_detected', 'browser failed blocked';
  ok $r->attempts->[2]->ok, 'stealth ok';
  like $r->markdown, qr/real useful content/, 'winning markdown carried';

  my @backends = map { $_->{backend} } @{ $c->log };
  is_deeply \@backends, [qw( crawl4ai_plain crawl4ai_browser crawl4ai_stealth )], 'ran in cost order';
};

subtest 'all strategies fail -> ok=0 with history' => sub {
  my $c = mk(
    { body => $thin },
    { body => $thin },
    { body => $blocked },
  );
  my $r = $c->crawl( url => 'https://example.com' )->get;
  ok !$r->ok, 'not ok';
  is $r->attempt_count, 3, 'all three tried';
  is $r->why_failed, 'bot_wall_detected', 'last reason surfaced';
  isa_ok $r->error, 'WWW::Crawl4AI::Error';
};

subtest 'a strategy that throws is recorded, chain continues' => sub {
  # Only one scripted response: plain throws (exhausted), browser throws,
  # stealth gets the good page.
  my $c = mk(
    { code => 500, message => 'boom', body => { detail => 'kaboom' } },   # plain -> api error
    { code => 500, message => 'boom', body => { detail => 'kaboom' } },   # browser -> api error
    { body => $good },                                                    # stealth ok
  );
  my $r = $c->markdown('https://example.com')->get;
  ok $r->ok, 'recovered after erroring strategies';
  is $r->backend, 'crawl4ai_stealth';
  is $r->attempts->[0]->why_failed, 'error', 'first attempt marked error';
  ok defined $r->attempts->[0]->error, 'error object captured';
};

subtest 'fallback => plain only runs Plain' => sub {
  my $c = Test::C4::Scripted->new(
    base_url => 'http://localhost:9999',
    fallback => 'plain',
    script   => [ { body => $good } ],
  );
  $loop->add($c);
  is_deeply $c->available_backends, ['crawl4ai_plain'], 'only plain in chain';
  my $r = $c->markdown('https://example.com')->get;
  ok $r->ok, 'plain-only ok';
  is $r->backend, 'crawl4ai_plain';
  is scalar @{ $c->log }, 1, 'exactly one dispatch';
};

subtest 'async callback strategy returns a Future' => sub {
  my $c = Test::C4::Scripted->new(
    base_url => 'http://localhost:9999',
    callback => sub {
      my ( $url ) = @_;
      return Future->done( { status_code => 200, markdown => ( 'from callback ' x 60 ) } );
    },
    script => [
      { body => $thin },      # plain
      { body => $thin },      # browser
      { body => $blocked },   # stealth
    ],
  );
  $loop->add($c);
  ok scalar( grep { $_ eq 'external_callback' } @{ $c->available_backends } ), 'callback in chain';
  my $r = $c->markdown('https://example.com')->get;
  ok $r->ok, 'callback rescued the crawl';
  is $r->backend, 'external_callback', 'callback won';
  like $r->markdown, qr/from callback/, 'callback markdown carried';
};

subtest 'adding to the loop eagerly builds the Net::Async::HTTP child' => sub {
  my $c = Test::C4::Scripted->new( base_url => 'http://localhost:9999', script => [] );
  ok !$c->{http}, 'no http child before being added to a loop';
  $loop->add($c);
  ok $c->{http}, 'http child built by _add_to_loop hook';
  isa_ok $c->{http}, 'Net::Async::HTTP';
};

done_testing;
