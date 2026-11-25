#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;
use WWW::Crawl4AI ();

# classify_is_good is a shared-dependency capability: it ships in WWW::Crawl4AI
# (fdadbc8), not here. Until the installed WWW::Crawl4AI carries it, its
# _attempt_for still calls Detect::is_good directly and no override can steer the
# chain -- there is nothing for this guard to assert yet. Skip loudly (with a
# reason, never silently) so the suite stays green against a pre-fix dep; the
# guard activates automatically once the shared fix is installed.
plan skip_all =>
  'installed WWW::Crawl4AI predates the classify_is_good dispatch (fdadbc8); '
  . 'the async override guard activates once the shared dep ships the fix'
  unless WWW::Crawl4AI->can('classify_is_good');

# Paired regression for karr #4 (mirrors sync WWW::Crawl4AI karr #2 / fdadbc8):
# the async chain must honour a WWW::Crawl4AI subclass override of the
# win/continue classifier. The async path owns NO copy of _attempt_for -- it
# delegates to $self->crawl4ai->_attempt_for, which (since fdadbc8) dispatches
# the decision through $www->classify_is_good. So an override on the underlying
# orchestrator steers which async strategy wins and whether the chain escalates,
# not merely the reported signals. This test fails the moment anyone forks a
# _attempt_for into the async lib that hard-calls WWW::Crawl4AI::Detect::is_good.

# Same scripted HTTP layer as t/10-chain.t: one pre-programmed response per
# strategy run, answered without touching the network.
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

# A quality bar stricter than Detect: the markdown must carry ACCEPTED. Detect
# is happy with any content-rich 200, so this override must REJECT a page Detect
# would win on.
{
  package Strict::WWW;
  use Moo;
  extends 'WWW::Crawl4AI';
  sub classify_is_good {
    my ( $self, $page, %opts ) = @_;
    return ( ( $page->{markdown} // '' ) =~ /ACCEPTED/ ) ? 1 : 0;
  }
}

# A bar looser than Detect: accept anything, including a thin page Detect rejects.
{
  package Loose::WWW;
  use Moo;
  extends 'WWW::Crawl4AI';
  sub classify_is_good { 1 }
}

# Clear env so the default chain is exactly plain -> browser -> stealth.
delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};

my $loop = IO::Async::Loop->new;

sub page {
  my ( %p ) = @_;
  return { results => [ { %p } ] };
}

my $rich_no_token = page( status_code => 200, markdown => ( 'real useful content ' x 40 ) );
my $rich_token    = page( status_code => 200, markdown => ( 'ACCEPTED useful content ' x 40 ) );
my $thin          = page( status_code => 200, markdown => 'too short' );

subtest 'stricter override makes the async chain CONTINUE past a Detect-good page' => sub {
  # Detect rates the plain page good, so without a working override plain would
  # win at attempt 0. The stricter classifier must reject it and drive to browser.
  my $www = Strict::WWW->new( base_url => 'http://localhost:9999' );
  my $c   = Test::C4::Scripted->new(
    base_url => 'http://localhost:9999',
    crawl4ai => $www,
    script   => [
      { body => $rich_no_token },   # plain:   Detect good | Strict rejected
      { body => $rich_token },      # browser: Detect good | Strict accepted
    ],
  );
  $loop->add($c);

  my $r = $c->markdown('https://example.com')->get;
  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_browser', 'browser won -- plain rejected by the async override';
  ok !$r->attempts->[0]->ok, 'plain attempt rejected by classify_is_good';
  ok  $r->attempts->[1]->ok, 'browser attempt accepted';
  my @backends = map { $_->{backend} } @{ $c->log };
  is_deeply \@backends, [qw( crawl4ai_plain crawl4ai_browser )],
    'chain continued past plain (would have stopped at plain without the override)';
};

subtest 'looser override makes the async chain STOP early on a Detect-bad page' => sub {
  # Detect rates the plain page thin, so without a working override the chain
  # escalates. The looser classifier must accept plain and stop.
  my $www = Loose::WWW->new( base_url => 'http://localhost:9999' );
  my $c   = Test::C4::Scripted->new(
    base_url => 'http://localhost:9999',
    crawl4ai => $www,
    script   => [
      { body => $thin },   # plain: Detect thin | Loose accepted
    ],
  );
  $loop->add($c);

  my $r = $c->markdown('https://example.com')->get;
  ok $r->ok, 'overall ok';
  is $r->backend, 'crawl4ai_plain', 'plain won -- accepted by the override despite being thin';
  ok $r->attempts->[0]->ok, 'plain attempt accepted by classify_is_good';
  my @backends = map { $_->{backend} } @{ $c->log };
  is_deeply \@backends, ['crawl4ai_plain'],
    'chain stopped at plain (would have escalated to browser without the override)';
};

done_testing;
