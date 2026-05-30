#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json decode_json );
use MIME::Base64 qw( encode_base64 );
use IO::Async::Loop;
use Future;
use URI;

use Net::Async::Crawl4AI;

# Answers every do_request with one scripted HTTP::Response and records the
# request the client built, so we can assert both sides without the network.
{
  package Test::C4::OneShot;
  use parent 'Net::Async::Crawl4AI';
  use Future;

  sub _init {
    my ( $self, $args ) = @_;
    $self->{response} = delete $args->{response};
    $self->SUPER::_init($args);
  }

  sub do_request {
    my ( $self, $req, $backend ) = @_;
    $self->{last_req} = $req;
    return Future->done( $self->{response} );
  }

  sub last_req { $_[0]->{last_req} }
}

delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};
my $loop = IO::Async::Loop->new;

sub mk {
  my ( $data ) = @_;
  my $res = HTTP::Response->new(
    200, 'OK', [ 'Content-Type' => 'application/json' ], encode_json($data),
  );
  my $c = Test::C4::OneShot->new( base_url => 'http://localhost:9999', response => $res );
  $loop->add($c);
  return $c;
}

subtest 'screenshot resolves to raw bytes' => sub {
  my $png = "\x89PNG\r\n\x1a\nrealbytes";
  my $c   = mk( { success => JSON::MaybeXS::true(), screenshot => encode_base64( $png, '' ) } );
  my $out = $c->screenshot( 'https://example.com', wait_for => 1 )->get;
  is $out, $png, 'decoded image bytes';
  is $c->last_req->uri, 'http://localhost:9999/screenshot', 'hit /screenshot';
};

subtest 'pdf resolves to raw bytes' => sub {
  my $pdf = '%PDF-1.4 realbytes';
  my $c   = mk( { success => JSON::MaybeXS::true(), pdf => encode_base64( $pdf, '' ) } );
  is $c->pdf('https://example.com')->get, $pdf, 'decoded pdf bytes';
  is $c->last_req->uri, 'http://localhost:9999/pdf', 'hit /pdf';
};

subtest 'html resolves to a string' => sub {
  my $c = mk( { html => '<h1>Hi</h1>', url => 'https://example.com', success => JSON::MaybeXS::true() } );
  is $c->html('https://example.com')->get, '<h1>Hi</h1>', 'html string';
};

subtest 'execute_js resolves to a normalized page with js_result' => sub {
  my $c = mk( {
    url => 'https://example.com', status_code => 200, markdown => 'real content ' x 10,
    js_execution_result => { results => ['Example Domain'], success => JSON::MaybeXS::true() },
  } );
  my $page = $c->execute_js( 'https://example.com', 'return document.title' )->get;
  is $page->{url}, 'https://example.com', 'page url';
  like $page->{markdown}, qr/real content/, 'markdown normalized';
  is_deeply $page->{js_result}{results}, ['Example Domain'], 'js_result carried';
  is_deeply decode_json( $c->last_req->content )->{scripts}, ['return document.title'], 'script coerced';
};

subtest 'llm resolves to an answer via GET' => sub {
  my $c   = mk( { answer => 'Some answer' } );
  my $ans = $c->llm( 'https://example.com', 'Who wrote this?', provider => 'openai/gpt-4o' )->get;
  is $ans, 'Some answer', 'answer extracted';
  is $c->last_req->method, 'GET', 'GET';
  my %q = URI->new( $c->last_req->uri )->query_form;
  is $q{q},        'Who wrote this?', 'question carried';
  is $q{provider}, 'openai/gpt-4o',   'provider carried';
  like "" . $c->last_req->uri, qr{/llm/https%3A}, 'page url escaped into path';
};

subtest 'token resolves to a JWT hash' => sub {
  my $c   = mk( { email => 'me@example.com', access_token => 'jwt.abc', token_type => 'bearer' } );
  my $tok = $c->token('me@example.com')->get;
  is $tok->{access_token}, 'jwt.abc', 'access_token';
  is $tok->{token_type},   'bearer',  'token_type';
};

subtest 'failed artifact fails the Future with a content error' => sub {
  my $c = mk( { success => JSON::MaybeXS::false() } );
  my $f = $c->screenshot('https://example.com');
  ok $f->is_failed, 'future failed';
  my ( $err ) = $f->failure;
  isa_ok $err, 'WWW::Crawl4AI::Error';
  is $err->type, 'content', 'content error';
};

done_testing;
