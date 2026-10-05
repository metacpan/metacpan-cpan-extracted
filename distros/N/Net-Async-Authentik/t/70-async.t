#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

# What can only go wrong asynchronously. The ported suites run every method
# through an answer that is already there; here the answers arrive only when
# the test says so, which is the only way to see what happens while requests
# are under way.

use Crypt::PK::RSA;
use Future;
use FakeAuthentik;
use FakeHTTP;
use Net::Async::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

{
  package DeferredHTTP;
  sub new { bless { fake => $_[1], queue => [] }, $_[0] }
  sub fake    { $_[0]{fake} }
  sub pending { scalar @{ $_[0]{queue} } }
  sub do_request {
    my ( $self, %arg ) = @_;
    my $future = Future->new;
    push @{ $self->{queue} }, [ $future, $arg{request} ];
    return $future;
  }
  sub answer_all {
    my ( $self ) = @_;
    while ( my $next = shift @{ $self->{queue} } ) { $next->[0]->done( $self->{fake}->request( $next->[1] ) ) }
    return;
  }
}

sub drain {
  my ( $http, @futures ) = @_;
  for ( 1 .. 50 ) {
    last unless grep { !$_->is_ready } @futures;
    $http->answer_all;
  }
  return;
}

sub probe_instance {
  my ( $fake ) = @_;
  my $provider = $fake->add( providers => {
    name => 'probe-provider', client_id => 'probe-client', client_secret => 'probe-secret',
    authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [],
    grant_types => ['client_credentials']
  } );
  $fake->add( applications => { name => 'Probe App', slug => 'probe-app', provider => $provider->{pk} } );
  return $provider;
}

subtest 'concurrent callers share the fetch' => sub {
  my $fake = FakeAuthentik->new;
  probe_instance($fake);
  my $http = DeferredHTTP->new($fake);
  my $now  = time;
  # jwks_min_age 0 so that an unknown key really does ask for the keys again;
  # the point here is that twenty such asks become one fetch, not twenty
  my $oidc = Net::Async::Authentik::OIDC->new(
    application_url => $fake->base.'/application/o/probe-app', http => $http,
    now => sub { $now }, jwks_min_age => 0 );
  my $count = sub { my ( $what ) = @_; scalar grep { $_->[1] =~ $what } @{ $fake->requests } };

  my $forged = do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $k };
  my @waiting = map { $oidc->verify_token_f( $fake->sign( $fake->claims_for, key => $forged, kid => 'unknown-'.$_ ), any_audience => 1 ) } 1 .. 20;
  drain( $http, @waiting );

  ok( !grep( { !$_->is_failed } @waiting ), 'twenty tokens with an unknown key are all rejected' );
  ok( !grep( { !$_->failure->isa('Net::Async::Authentik::Error::Validation') } @waiting ), 'with validation errors' );
  is( $count->(qr/openid-configuration/), 1, 'one discovery request for all twenty' );
  is( $count->(qr{/jwks/}), 2, 'two key fetches for all twenty: the first, and one more for the unknown keys' );
};

subtest 'the key fetch is throttled' => sub {
  my $fake = FakeAuthentik->new;
  probe_instance($fake);
  my $http = DeferredHTTP->new($fake);
  my $now  = time;
  my $oidc = Net::Async::Authentik::OIDC->new(
    application_url => $fake->base.'/application/o/probe-app', http => $http, now => sub { $now } );
  my $count = sub { scalar grep { $_->[1] =~ m{/jwks/} } @{ $fake->requests } };
  my $forged = do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $k };
  my $token  = sub { $fake->sign( $fake->claims_for, key => $forged, kid => 'made-up' ) };

  my @first = map { $oidc->verify_token_f( $token->(), any_audience => 1 ) } 1 .. 5;
  drain( $http, @first );
  is( $count->(), 1, 'inside jwks_min_age the keys are not fetched again' );

  $now += 120;
  my $later = $oidc->verify_token_f( $token->(), any_audience => 1 );
  drain( $http, $later );
  is( $count->(), 2, 'once it has passed, they are' );
};

subtest 'cancelling one caller leaves the fetch alone' => sub {
  my $fake = FakeAuthentik->new;
  probe_instance($fake);
  my $http = DeferredHTTP->new($fake);
  my $oidc = Net::Async::Authentik::OIDC->new(
    application_url => $fake->base.'/application/o/probe-app', http => $http );

  my $first  = $oidc->discovery_f;
  my $second = $oidc->discovery_f;
  is( $http->pending, 1, 'two callers, one request' );
  $first->cancel;
  drain( $http, $second );
  ok( $second->is_done, 'the other caller still gets its answer' );
  is( $second->get->{issuer}, $fake->base.'/application/o/probe-app/', 'the right one' );
  ok( $first->is_cancelled, 'and the one that went away is cancelled, not failed' );
};

subtest 'requests run side by side' => sub {
  my $fake = FakeAuthentik->new;
  my $http = DeferredHTTP->new($fake);
  my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token, http => $http )->api;
  my @calls = ( $api->version_f, $api->me_f, $api->settings_f );
  is( $http->pending, 3, 'three requests are out at once' );
  $http->answer_all;
  ok( !grep( { !$_->is_done } @calls ), 'and all three complete' );
  is( $calls[0]->get->{version_current}, '2026.8.3', 'with their own answers' );
};

subtest '_paged_f over three pages' => sub {
  my $fake = FakeAuthentik->new;
  $fake->add( users => { username => sprintf( 'bulk-%03d', $_ ), name => 'Bulk '.$_ } ) for 1 .. 25;
  my $http = FakeHTTP->new( fake => $fake );
  my $api  = Net::Async::Authentik::API->new(
    base_url => $fake->base, token => $fake->token, http => $http, page_size => 10 );
  my $all = $api->list_users_f->get;
  is( scalar @$all, 26, 'every user, over three pages' );
  is( scalar @{ $fake->requests }, 3, 'in three requests' );

  # an answer whose next points at a page already fetched must not loop
  $fake->break_pagination;
  my $guarded = $api->list_users_f->get;
  cmp_ok( scalar @$guarded, '>', 0, 'a broken pagination still returns' );
  cmp_ok( scalar @$guarded, '<=', 26, 'and does not run away' );
};

subtest 'not in a loop' => sub {
  # Net::Async::HTTP dies instead of failing when it is in no loop; that must
  # not reach the caller as an exception
  my $ak = Net::Async::Authentik->new( base_url => 'http://127.0.0.1:9', application => 'x', token => 't' );
  for my $future ( $ak->oidc->discovery_f, $ak->api->version_f ) {
    ok( $future->is_failed, 'a failed future, not an exception' );
    isa_ok( ( $future->failure )[0], 'Net::Async::Authentik::Error::Network' );
    like( ( $future->failure )[0]->message, qr/added to a loop/, 'saying what is missing' );
  }
};

subtest 'wrong arguments fail the future' => sub {
  my $fake = FakeAuthentik->new;
  my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token,
    http => FakeHTTP->new( fake => $fake ) )->api;
  my @bad = (
    [ 'ensure_user without a username' => $api->ensure_user_f( name => 'x' ) ],
    [ 'ensure_binding without an order' => $api->ensure_binding_f( flow => 'f', stage => 's' ) ],
    [ 'find_user without a username'   => $api->find_user_f(undef) ],
    [ 'scopes => undef'                => $api->resolve_f( { scopes => undef } ) ],
    [ 'ensure_stage through all'       => $api->ensure_stage_f( all => name => 'x' ) ],
    [ 'ensure_token with expires'      => $api->ensure_token_f( identifier => 'x', expires => 'now' ) ]
  );
  for my $case (@bad) {
    my ( $why, $future ) = @$case;
    ok( $future->is_failed, $why.': failed, not thrown' );
    isa_ok( ( $future->failure )[0], 'Net::Async::Authentik::Error::Validation', $why );
  }

  my $no_token = Net::Async::Authentik->new( base_url => $fake->base,
    http => FakeHTTP->new( fake => $fake ) )->api->me_f;
  ok( $no_token->is_failed, 'a missing token fails the future too' );
  isa_ok( ( $no_token->failure )[0], 'Net::Async::Authentik::Error::Validation' );
};

subtest 'a future nobody holds still does the work' => sub {
  # Not what one might hope. The async sub has already started, and the HTTP
  # future it is waiting on is held by the HTTP client, so the continuation
  # runs to the end and authentik is written to - the caller just never hears
  # the outcome, and Future::AsyncAwait says so. Hold the future.
  my $fake = FakeAuthentik->new;
  my $http = DeferredHTTP->new($fake);
  my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token, http => $http )->api;

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    {
      my $lost = $api->ensure_group_f( name => 'ghost' );   # dropped on purpose
    }
    drain( $http );
    $http->answer_all for 1 .. 5;
  }
  is( $fake->writes, 1, 'the group was created even though nobody waited' );
  ok( scalar( grep { /lost its returning future/ } @warnings ), 'and Perl said the future was lost' );

  # the work is whole, not half: the next run finds it and changes nothing
  my $held = $api->ensure_group_f( name => 'ghost' );
  drain( $http, $held );
  is( $held->get->{changed}, '', 'the second run finds a finished object' );
  is( $fake->writes, 1, 'and writes nothing more' );
};

subtest 'nothing throws, not even a body that cannot be encoded' => sub {
  my $fake = FakeAuthentik->new;
  my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token,
    http => FakeHTTP->new( fake => $fake ) )->api;
  # the JSON codec dies on this, and building the request happens before any
  # await, so without care it would throw out of a method that promised a future
  my $future = eval { $api->call_f( POST => '/core/groups/', { name => 'x', bad => sub {1} } ) };
  ok( $future, 'call_f with an unencodable body gives a future back' );
  ok( $future && $future->is_failed, 'a failed one' );
  isa_ok( ( $future->failure )[0], 'Net::Async::Authentik::Error::Validation' ) if $future;
  like( ( $future->failure )[0]->message, qr/could not be built/, 'saying what went wrong' ) if $future;

  my $direct = eval { $api->send_request_f( POST => 'http://x/', json => { bad => sub {1} } ) };
  ok( $direct && $direct->is_failed, 'and so does send_request_f on its own' );
};

subtest 'a lookup that fails is not a missing object' => sub {
  # a refused request during ensure_binding_f used to be reported as "no flow"
  { package RefusedHTTP; use Future;
    sub new { bless {}, shift }
    sub do_request { Future->fail('127.0.0.1:9 - connect: Connection refused') } }
  my $api = Net::Async::Authentik->new( base_url => 'http://127.0.0.1:9', token => 't',
    http => RefusedHTTP->new )->api;
  my $future = $api->ensure_binding_f( flow => 'some-flow', stage => 'some-stage', order => 10 );
  ok( $future->is_failed, 'it fails' );
  my ( $error ) = $future->failure;
  isa_ok( $error, 'Net::Async::Authentik::Error::Network', 'with the real reason' );
  unlike( $error->message, qr/no flow/, 'not as a missing flow' );
};

subtest 'an argument list that does not make pairs' => sub {
  # on Future::AsyncAwait 0.71 a suspended frame holding a reference corrupts
  # the heap at exit, and an odd-sized list is the easiest way for a caller to
  # put one there by accident. See docs/future-asyncawait-0.71-crash.pl.
  my $fake = FakeAuthentik->new;
  probe_instance($fake);
  my $ak = Net::Async::Authentik->new( base_url => $fake->base, application => 'probe-app',
    token => $fake->token, http => FakeHTTP->new( fake => $fake ) );
  my %odd = (
    'device_authorization_f' => $ak->oidc->device_authorization_f( {} ),
    'authorization_url_f'    => $ak->oidc->authorization_url_f( {} ),
    'introspect_f'           => $ak->oidc->introspect_f( 'tok', {} ),
    'revoke_f'               => $ak->oidc->revoke_f( 'tok', {} ),
    'verify_token_f'         => $ak->oidc->verify_token_f( 'tok', {} ),
    'ensure_user_f'          => $ak->api->ensure_user_f( {} ),
    'ensure_binding_f'       => $ak->api->ensure_binding_f( {} ),
    'ensure_stage_f'         => $ak->api->ensure_stage_f( password => {} ),
    'list_bindings_f'        => $ak->api->list_bindings_f( {} )
  );
  for my $name ( sort keys %odd ) {
    ok( $odd{$name}->is_failed, $name.': refused, not taken apart' );
    isa_ok( ( $odd{$name}->failure )[0], 'Net::Async::Authentik::Error::Validation', $name );
    like( ( $odd{$name}->failure )[0]->message, qr/do not make pairs/, $name.': says what is wrong' );
  }

  # and a well-formed call with the same reference still works
  ok( $ak->api->ensure_group_f( name => 'pairs', attributes => { a => 'b' } )->get->{object},
    'a reference in a value is fine' );
};

subtest 'the same answers as the synchronous client' => sub {
  # the two share build_request, read_response and Diff, so a failure here
  # means they have drifted
  my $fake = FakeAuthentik->new;
  my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token,
    http => FakeHTTP->new( fake => $fake ) )->api;
  is( $api->diff_class, 'WWW::Authentik::Diff', 'the comparison is the synchronous one' );
  is_deeply( [ sort keys %{ $api->resolvable_fields } ], [ sort keys %{ WWW::Authentik::API->resolvable_fields } ],
    'and so is the resolution table' );
  is( $api->uuid_pattern, WWW::Authentik::API->uuid_pattern, 'and both identifier shapes' );
  is( $api->integer_pattern, WWW::Authentik::API->integer_pattern, 'the other one too' );

  # every public method of the synchronous API exists here, with _f where it
  # does I/O. `ua` is the one on purpose: this client has `http` instead.
  my %on_purpose = map { $_ => 1 } qw( ua );
  my @missing;
  for my $name ( sort keys %WWW::Authentik::API:: ) {
    next if $name =~ /\A_/ || $on_purpose{$name};
    no strict 'refs';
    next unless defined &{"WWW::Authentik::API::$name"};
    next if Net::Async::Authentik::API->can( $name.'_f' ) || Net::Async::Authentik::API->can($name);
    push @missing, $name;
  }
  is_deeply( \@missing, [], 'no method of the synchronous API is missing here' )
    or diag 'missing: '.join ', ', @missing;

  my @extra;
  for my $name ( sort keys %Net::Async::Authentik::API:: ) {
    next unless $name =~ /\A([a-z][a-z0-9_]*)_f\z/;
    my $sync = $1;
    next if $sync =~ /\A_/;
    no strict 'refs';
    next unless defined &{"Net::Async::Authentik::API::$name"};
    push @extra, $name unless WWW::Authentik::API->can($sync);
  }
  is_deeply( \@extra, [], 'and nothing here was invented without the synchronous twin' )
    or diag 'extra: '.join ', ', @extra;

  my $error = error_of { $api->create_user_f( { username => 'x' } )->get };
  isa_ok( $error, 'WWW::Authentik::Error::API', 'an API error is the synchronous class as well' );
  isa_ok( $error, 'Net::Async::Authentik::Error', 'and this one' );
  is_deeply( $error->field_errors, { name => ['This field is required.'] }, 'read by the shared code' );
};

done_testing;
