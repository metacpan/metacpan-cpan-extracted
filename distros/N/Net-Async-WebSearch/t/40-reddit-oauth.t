#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use MIME::Base64 qw( decode_base64 );

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Reddit::OAuth;

# Scripted HTTP double: serves token POSTs and search GETs out of a simple
# dispatcher. Tracks every request so we can assert call patterns.
{
  package Test::WS::MockHTTP;
  use Future;
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json );
  sub new {
    my ( $class, %args ) = @_;
    bless {
      token_responses  => $args{token_responses}  || [],
      search_responses => $args{search_responses} || [],
      log              => [],
    }, $class;
  }
  sub log { $_[0]->{log} }
  sub configure {}
  sub configure_unknown {}
  sub add_child {}
  sub remove_child {}
  sub _add_to_loop {}
  sub _remove_from_loop {}
  sub parent { }
  sub loop { }
  sub notifier_name { 'mock' }

  sub do_request {
    my ( $self, %args ) = @_;
    my $req = $args{request};
    my $url = $req->uri.'';
    my $entry = {
      method  => $req->method,
      url     => $url,
      headers => { map { $_ => $req->header($_) } $req->header_field_names },
      content => $req->content,
    };
    push @{ $self->{log} }, $entry;

    if ( $url =~ m{/api/v1/access_token$} ) {
      my $step = shift @{ $self->{token_responses} }
        or return Future->fail('token script exhausted');
      my $body = ref $step->{body} ? encode_json($step->{body}) : ($step->{body} // '{}');
      my $res = HTTP::Response->new(
        $step->{code} // 200, $step->{msg} // 'OK',
        [ 'Content-Type' => 'application/json' ], $body,
      );
      $res->request($req);
      return Future->done($res);
    }
    # Search
    my $step = shift @{ $self->{search_responses} }
      or return Future->fail("search script exhausted for $url");
    my $body = ref $step->{body} ? encode_json($step->{body}) : ($step->{body} // '');
    my $res = HTTP::Response->new(
      $step->{code} // 200, $step->{msg} // 'OK',
      [ 'Content-Type' => 'application/json' ], $body,
    );
    $res->request($req);
    return Future->done($res);
  }
}

sub listing_payload {
  my (@posts) = @_;
  return {
    data => {
      children => [
        map { +{ data => $_ } } @posts,
      ],
    },
  };
}

sub make_provider_loop {
  my (%http_args) = @_;
  my $loop = IO::Async::Loop->new;
  my $mock = Test::WS::MockHTTP->new(%http_args);
  my $ws = Net::Async::WebSearch->new( http => $mock );
  $loop->add($ws);
  return ( $ws, $mock, $loop );
}

subtest 'client_credentials: token request + bearer on search' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses => [
      { body => { access_token => 'TOK1', token_type => 'bearer', expires_in => 3600 } },
    ],
    search_responses => [
      { body => listing_payload(
          { title => 'Async IO in Perl', url => 'https://example.com/p1',
            permalink => '/r/perl/comments/1/', subreddit => 'perl',
            author => 'u', score => 10, num_comments => 2, created_utc => 1_700_000_000 },
        ),
      },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CSECRET',
    user_agent    => 'test/1.0',
  );
  $ws->add_provider($p);

  my $out = $ws->search( query => 'perl async', only => ['reddit-oauth'] )->get;

  is scalar @{ $mock->log }, 2, 'two HTTP calls total';
  my ($tok, $srch) = @{ $mock->log };

  is $tok->{method}, 'POST', 'token via POST';
  like $tok->{url}, qr{/api/v1/access_token$}, 'token endpoint';
  like $tok->{content}, qr/\bgrant_type=client_credentials\b/, 'correct grant_type';
  my ($b64) = $tok->{headers}{Authorization} =~ /^Basic (\S+)/;
  ok $b64, 'Basic auth header present';
  is decode_base64($b64), 'CID:CSECRET', 'credentials base64-encoded correctly';

  like $srch->{url}, qr{^https://oauth\.reddit\.com/search}, 'search hits oauth host';
  is $srch->{headers}{Authorization}, 'Bearer TOK1', 'bearer token attached';
  is $srch->{headers}{'User-Agent'},  'test/1.0',    'custom UA used';

  is scalar @{ $out->{results} }, 1, 'one result parsed';
  is $out->{results}[0]->title, 'Async IO in Perl', 'title carried through';
  is $out->{results}[0]->extra->{subreddit}, 'perl', 'subreddit in extras';
};

subtest 'cached token is reused on second search' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [
      { body => { access_token => 'TOK-CACHED', expires_in => 3600 } },
    ],  # only ONE token response — second call must use cached
    search_responses => [
      { body => listing_payload(
          { title => 'r1', url => 'https://ex/1', permalink => '/x/1', subreddit => 's', created_utc => 1 }
        ) },
      { body => listing_payload(
          { title => 'r2', url => 'https://ex/2', permalink => '/x/2', subreddit => 's', created_utc => 2 }
        ) },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
  );
  $ws->add_provider($p);

  $ws->search( query => 'a', only => ['reddit-oauth'] )->get;
  $ws->search( query => 'b', only => ['reddit-oauth'] )->get;

  my @token_calls  = grep { $_->{url} =~ m{/access_token$} } @{ $mock->log };
  my @search_calls = grep { $_->{url} !~ m{/access_token$} } @{ $mock->log };
  is scalar @token_calls,  1, 'only one token request (cached on 2nd call)';
  is scalar @search_calls, 2, 'two search calls';
  is $search_calls[1]->{headers}{Authorization}, 'Bearer TOK-CACHED',
    'cached token reused';
};

subtest 'expired token triggers refresh' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [
      # First token already basically expired (expires_in smaller than token_margin → forces refresh).
      { body => { access_token => 'OLD', expires_in => 10 } },
      { body => { access_token => 'NEW', expires_in => 3600 } },
    ],
    search_responses => [
      { body => listing_payload(
          { title => 'r1', url => 'https://ex/1', permalink => '/x/1', subreddit => 's', created_utc => 1 }
        ) },
      { body => listing_payload(
          { title => 'r2', url => 'https://ex/2', permalink => '/x/2', subreddit => 's', created_utc => 2 }
        ) },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
    token_margin  => 60,  # > expires_in(10) → first token is immediately "stale"
  );
  $ws->add_provider($p);

  $ws->search( query => 'a', only => ['reddit-oauth'] )->get;
  $ws->search( query => 'b', only => ['reddit-oauth'] )->get;

  my @token_calls  = grep { $_->{url} =~ m{/access_token$} } @{ $mock->log };
  my @search_calls = grep { $_->{url} !~ m{/access_token$} } @{ $mock->log };
  is scalar @token_calls,  2, 'token re-fetched after expiry';
  is $search_calls[0]->{headers}{Authorization}, 'Bearer OLD', 'first uses OLD';
  is $search_calls[1]->{headers}{Authorization}, 'Bearer NEW', 'second uses NEW';
};

subtest 'password grant sends username/password' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [
      { body => { access_token => 'P', expires_in => 3600 } },
    ],
    search_responses => [
      { body => listing_payload() },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
    grant_type    => 'password',
    username      => 'alice',
    password      => 'pw123',
  );
  $ws->add_provider($p);
  $ws->search( query => 'q', only => ['reddit-oauth'] )->get;

  my ($tok) = grep { $_->{url} =~ m{/access_token$} } @{ $mock->log };
  like $tok->{content}, qr/\bgrant_type=password\b/, 'password grant';
  like $tok->{content}, qr/\busername=alice\b/,     'username in body';
  like $tok->{content}, qr/\bpassword=pw123\b/,     'password in body';
};

subtest 'installed grant sends device_id and the installed_client grant URI' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [
      { body => { access_token => 'I', expires_in => 3600 } },
    ],
    search_responses => [
      { body => listing_payload() },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => '',
    grant_type    => 'installed',
    device_id     => 'DEVICE-ABCDEF0123456789',
  );
  $ws->add_provider($p);
  $ws->search( query => 'q', only => ['reddit-oauth'] )->get;

  my ($tok) = grep { $_->{url} =~ m{/access_token$} } @{ $mock->log };
  like $tok->{content}, qr/grant_type=https.*installed_client/,
    'installed_client grant URI';
  like $tok->{content}, qr/device_id=DEVICE-ABCDEF0123456789/,
    'device_id carried';
};

subtest 'constructor validates required params' => sub {
  eval { Net::Async::WebSearch::Provider::Reddit::OAuth->new( client_secret => 'x' ) };
  like $@, qr/client_id/, 'missing client_id rejected';

  eval { Net::Async::WebSearch::Provider::Reddit::OAuth->new( client_id => 'x' ) };
  like $@, qr/client_secret/, 'missing client_secret rejected';

  eval {
    Net::Async::WebSearch::Provider::Reddit::OAuth->new(
      client_id => 'x', client_secret => 'y', grant_type => 'password',
    );
  };
  like $@, qr/username/, 'password grant requires username/password';
};

subtest 'authorize_url builds Reddit consent URL (no network)' => sub {
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
    grant_type    => 'authorization_code',
  );
  my $url = $p->authorize_url(
    redirect_uri => 'https://app/cb',
    scope        => [qw( read identity )],
    state        => 'fixed-state',
  );
  like $url, qr{^https://www\.reddit\.com/api/v1/authorize\?}, 'authorize host';
  like $url, qr/\bclient_id=CID\b/,               'client_id in URL';
  like $url, qr/\bresponse_type=code\b/,          'response_type=code';
  like $url, qr/\bstate=fixed-state\b/,           'state carried';
  like $url, qr/\bduration=permanent\b/,          'duration=permanent default';
  like $url, qr/\bredirect_uri=https%3A%2F%2Fapp%2Fcb\b/, 'redirect_uri url-encoded';
  like $url, qr/\bscope=read(?:%20|\+)identity\b/, 'scope joined and encoded';

  my $auto = $p->authorize_url( redirect_uri => 'https://app/cb' );
  like $auto, qr/\bstate=[A-Za-z0-9]{20,}\b/, 'state auto-generated when omitted';
};

subtest 'complete_authorization exchanges code for tokens + fires callback' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses => [
      { body => {
          access_token  => 'AC-USER',
          refresh_token => 'RT-USER',
          expires_in    => 3600,
          scope         => 'read identity',
      } },
    ],
    search_responses => [],
  );
  my @callback;
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
    grant_type    => 'authorization_code',
    on_token_refresh => sub { push @callback, { %{$_[1]} } },
  );
  $ws->add_provider($p);

  my $tok = $p->complete_authorization(
    http         => $ws->http,
    code         => 'CODE-ABC',
    redirect_uri => 'https://app/cb',
  )->get;
  is $tok, 'AC-USER', 'returns access_token';
  is $p->access_token,  'AC-USER', 'access_token cached';
  is $p->refresh_token, 'RT-USER', 'refresh_token cached';
  ok $p->token_expires_at > time, 'expiry in future';
  is scalar @callback, 1, 'on_token_refresh fired';
  is $callback[0]{refresh_token}, 'RT-USER', 'callback carried raw response';

  my ($call) = @{ $mock->log };
  like $call->{url}, qr{/api/v1/access_token$}, 'posted to token endpoint';
  like $call->{content}, qr/\bgrant_type=authorization_code\b/;
  like $call->{content}, qr/\bcode=CODE-ABC\b/;
  like $call->{content}, qr/\bredirect_uri=https%3A%2F%2Fapp%2Fcb\b/;
};

subtest 'seeded refresh_token drives refresh grant on first search' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses => [
      { body => { access_token => 'AC-REFRESHED', expires_in => 3600 } },
    ],
    search_responses => [
      { body => listing_payload(
          { title => 'r', url => 'https://ex/1', permalink => '/x/1',
            subreddit => 's', created_utc => 1 }
      ) },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => 'CID',
    client_secret => 'CS',
    grant_type    => 'authorization_code',
    refresh_token => 'RT-STORED',
  );
  $ws->add_provider($p);
  $ws->search( query => 'q', only => ['reddit-oauth'] )->get;

  my ($tok, $srch) = @{ $mock->log };
  like $tok->{content}, qr/\bgrant_type=refresh_token\b/, 'refresh grant used';
  like $tok->{content}, qr/\brefresh_token=RT-STORED\b/,  'stored RT sent';
  is $srch->{headers}{Authorization}, 'Bearer AC-REFRESHED',
    'new access_token on search request';
};

subtest 'seeded access_token skips initial token call' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [],  # must not be called
    search_responses => [
      { body => listing_payload(
          { title => 'r', url => 'https://ex/1', permalink => '/x/1',
            subreddit => 's', created_utc => 1 }
      ) },
    ],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id         => 'CID',
    client_secret     => 'CS',
    grant_type        => 'authorization_code',
    access_token      => 'AC-SEED',
    token_expires_at  => time + 3600,
  );
  $ws->add_provider($p);
  $ws->search( query => 'q', only => ['reddit-oauth'] )->get;
  my ($only) = @{ $mock->log };
  is scalar @{ $mock->log }, 1, 'exactly one HTTP call (search, no token)';
  is $only->{headers}{Authorization}, 'Bearer AC-SEED', 'seeded token used';
};

subtest 'token_state round-trips through new()' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses => [
      { body => { access_token => 'A1', refresh_token => 'R1', expires_in => 3600 } },
    ],
    search_responses => [],
  );
  my $p1 = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id => 'CID', client_secret => 'CS',
    grant_type => 'authorization_code',
  );
  $ws->add_provider($p1);
  $p1->complete_authorization(
    http => $ws->http, code => 'C', redirect_uri => 'https://app/cb',
  )->get;
  my $state = $p1->token_state;
  is $state->{access_token},  'A1', 'state has access_token';
  is $state->{refresh_token}, 'R1', 'state has refresh_token';

  my $p2 = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id => 'CID', client_secret => 'CS',
    grant_type => 'authorization_code',
    %$state,
  );
  is $p2->access_token,  'A1', 'rehydrated access_token';
  is $p2->refresh_token, 'R1', 'rehydrated refresh_token';
};

subtest 'authorization_code without seed fails search with a clear error' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [],
    search_responses => [],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id => 'CID', client_secret => 'CS',
    grant_type => 'authorization_code',
  );
  $ws->add_provider($p);
  my $out = $ws->search( query => 'q', only => ['reddit-oauth'] )->get;
  is scalar @{ $out->{errors} }, 1, 'one error';
  like $out->{errors}[0]{error}, qr/authorize_url|complete_authorization/,
    'error names the primitives';
};

subtest 'token endpoint 4xx surfaces as Future fail' => sub {
  my ( $ws, $mock ) = make_provider_loop(
    token_responses  => [
      { code => 401, msg => 'Unauthorized', body => { error => 'invalid_grant' } },
    ],
    search_responses => [],
  );
  my $p = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id => 'CID', client_secret => 'CS',
  );
  $ws->add_provider($p);

  my $out = $ws->search( query => 'q', only => ['reddit-oauth'] )->get;
  is scalar @{ $out->{results} }, 0, 'no results';
  is scalar @{ $out->{errors} }, 1, 'one provider error';
  like $out->{errors}[0]{error}, qr/token HTTP 401/, 'token error surfaced';
};

done_testing;
