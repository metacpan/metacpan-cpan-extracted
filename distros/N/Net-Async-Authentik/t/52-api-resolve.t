#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeAuthentik;
use FakeHTTP;
use Net::Async::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $fake = FakeAuthentik->new;
my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token, http => FakeHTTP->new( fake => $fake ) )->api;

my $flow        = $api->find_flow_f('default-authentication-flow')->get;
my $certificate = $api->find_certificate_f('authentik Self-signed Certificate')->get;
my $group       = $api->create_group_f( { name => 'staff' } )->get;
my $openid      = $api->find_scope_mappings_by_scope_f('openid')->get->[0];
my $email       = $api->find_scope_mappings_by_scope_f('email')->get->[0];

# a provider whose name looks like a primary key, and another one that really
# has that key
my $named_123 = $fake->add( providers => { name => '123', authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [] } );
my $pk_123    = $fake->add( providers => { pk => 123, name => 'real-provider', authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [] } );
isnt( $named_123->{pk}, 123, 'the provider called "123" has another primary key' );

subtest 'the two identifier shapes are named, not hidden' => sub {
  # the async twin asks for these instead of writing the patterns again
  my $uuid = WWW::Authentik::API->uuid_pattern;
  my $int  = WWW::Authentik::API->integer_pattern;
  like( '11111111-2222-4333-8444-555555555555', $uuid, 'a UUID' );
  unlike( 'default-authentication-flow', $uuid, 'and a slug is not one' );
  like( '123', $int, 'a run of digits' );
  unlike( '12a', $int, 'and not a name that starts with one' );
  is( $api->resolvable_fields->{provider}{raw}, $int, 'the table uses them' );
  is( $api->resolvable_fields->{authorization_flow}{raw}, $uuid, 'both of them' );
};

subtest 'an integer field' => sub {
  is( $api->resolve_f( { provider => '123' } )->get->{provider}, '123', 'an integer is the primary key, never a name' );
  is( $api->resolve_f( { provider => 123 } )->get->{provider}, 123, 'as a number too' );
  is( $api->resolve_f( { provider_name => '123' } )->get->{provider}, $named_123->{pk},
    'the forced form looks the name up even when it looks like a key' );
  is( $api->resolve_f( { provider => 'real-provider' } )->get->{provider}, 123, 'anything that is not an integer is a name' );

  my $both = error_of { $api->resolve_f( { provider => 1, provider_name => 'real-provider' } )->get };
  isa_ok( $both, 'Net::Async::Authentik::Error::Validation', 'both forms at once' );
  like( "$both", qr/provider or provider_name/, 'and says which two' );

  my $gone = error_of { $api->resolve_f( { provider_name => 'nobody' } )->get };
  isa_ok( $gone, 'Net::Async::Authentik::Error::Validation', 'a name nothing matches' );
  like( "$gone", qr/no oauth2 provider named "nobody"/, 'naming the field and the value' );

  my $user = $api->create_user_f( { username => 'alice', name => 'Alice' } )->get;
  is( $api->resolve_f( { user => $user->{pk} } )->get->{user}, $user->{pk}, 'the user field takes a key' );
  is( $api->resolve_f( { user_name => 'alice' } )->get->{user}, $user->{pk}, 'and a username when forced' );
};

subtest 'a UUID field' => sub {
  is( $api->resolve_f( { authorization_flow => $flow->{pk} } )->get->{authorization_flow}, $flow->{pk}, 'a UUID is the key' );
  is( $api->resolve_f( { authorization_flow => 'default-authentication-flow' } )->get->{authorization_flow}, $flow->{pk},
    'anything else is a slug' );

  # a slug may have the shape of a UUID; then only the forced form reaches it
  my $odd = $api->create_flow_f( { name => 'Odd', slug => '11111111-2222-4333-8444-555555555555',
    title => 'Odd', designation => 'authentication' } )->get;
  is( $api->resolve_f( { invalidation_flow => '11111111-2222-4333-8444-555555555555' } )->get->{invalidation_flow},
    '11111111-2222-4333-8444-555555555555', 'a UUID shape is taken as the key' );
  is( $api->resolve_f( { invalidation_flow_slug => '11111111-2222-4333-8444-555555555555' } )->get->{invalidation_flow},
    $odd->{pk}, 'the forced form looks the slug up anyway' );
  isnt( $odd->{pk}, '11111111-2222-4333-8444-555555555555', 'and the two really differ' );

  is( $api->resolve_f( { signing_key_name => 'authentik Self-signed Certificate' } )->get->{signing_key},
    $certificate->{pk}, 'a certificate by name' );
  like( error_of { $api->resolve_f( { configure_flow_slug => 'nope' } )->get }, qr/no flow named "nope"/, 'an unknown flow' );
  $api->delete_flow_f( $odd->{slug} )->get;
};

subtest 'lists' => sub {
  is_deeply( $api->resolve_f( { groups => [ $group->{pk} ] } )->get->{groups}, [ $group->{pk} ], 'a list of keys' );
  is_deeply( $api->resolve_f( { groups => ['staff'] } )->get->{groups}, [ $group->{pk} ], 'a list of names' );
  is_deeply( $api->resolve_f( { groups => [ $group->{pk}, 'staff' ] } )->get->{groups}, [ $group->{pk}, $group->{pk} ],
    'and a mixture' );
  is_deeply( $api->resolve_f( { group_names => ['staff'] } )->get->{groups}, [ $group->{pk} ], 'the forced form' );
  is_deeply( $api->resolve_f( { groups => [] } )->get->{groups}, [], 'an empty list stays empty' );
  like( error_of { $api->resolve_f( { group_names => ['nope'] } )->get }, qr/no group named "nope"/, 'an unknown group' );
};

subtest 'scopes' => sub {
  is_deeply( $api->resolve_f( { scopes => [qw( openid email )] } )->get->{property_mappings},
    [ $openid->{pk}, $email->{pk} ], 'scopes become property_mappings, in order' );
  ok( !exists $api->resolve_f( { scopes => ['openid'] } )->get->{scopes}, 'and scopes is gone' );
  my $clash = error_of { $api->resolve_f( { scopes => ['openid'], property_mappings => [ $openid->{pk} ] } )->get };
  isa_ok( $clash, 'Net::Async::Authentik::Error::Validation', 'scopes together with property_mappings' );
  like( "$clash", qr/scopes or property_mappings/, 'and says which two' );
  like( error_of { $api->resolve_f( { scopes => ['no-such-scope'] } )->get }, qr/no scope mapping for the scope/, 'an unknown scope' );
};

subtest 'a mistake is not taken for a wish' => sub {
  # an undef where a name belongs is a bug in the caller, and for scopes a
  # costly one: taken as an empty list it would strip every mapping
  my $scopes = error_of { $api->resolve_f( { scopes => undef } )->get };
  isa_ok( $scopes, 'Net::Async::Authentik::Error::Validation', 'scopes => undef' );
  like( "$scopes", qr/take every mapping away/, 'and says what it would have done' );
  is_deeply( $api->resolve_f( { scopes => [] } )->get->{property_mappings}, [], 'an empty list still means empty' );
  isa_ok( error_of { $api->resolve_f( { scopes => 'openid' } )->get }, 'Net::Async::Authentik::Error::Validation', 'scopes as a string' );

  my $forced = error_of { $api->resolve_f( { provider_name => undef } )->get };
  isa_ok( $forced, 'Net::Async::Authentik::Error::Validation', 'provider_name => undef' );
  like( "$forced", qr/provider_name is undef/, 'and names the key' );
  is_deeply( $api->resolve_f( { provider => undef } )->get, { provider => undef }, 'while provider => undef still passes through' );

  my $ref = error_of { $api->resolve_f( { user => {} } )->get };
  isa_ok( $ref, 'Net::Async::Authentik::Error::Validation', 'a reference where a name belongs' );
  like( "$ref", qr/got a hash reference/, 'and says what it got' );
  unlike( "$ref", qr/HASH\(0x/, 'without an address in the message' );
};

subtest 'a finder needs something to find' => sub {
  # an undef key used to fetch the whole table and compare every row to undef
  for my $finder ( map { $_.'_f' } qw( find_user find_group find_oauth2_provider find_scope_mapping
                      find_certificate find_stage find_application find_flow find_token ) ) {
    isa_ok( error_of { $api->$finder(undef)->get }, 'Net::Async::Authentik::Error::Validation', $finder.'(undef)' );
    isa_ok( error_of { $api->$finder('')->get }, 'Net::Async::Authentik::Error::Validation', $finder.q{('')} );
  }
};

subtest 'everything else is left alone' => sub {
  my $rep = $api->resolve_f( { name => 'x', client_type => 'public', redirect_uris => [ { url => 'u' } ], provider => 7 } )->get;
  is( $rep->{name}, 'x', 'a plain field' );
  is( $rep->{client_type}, 'public', 'another one' );
  is_deeply( $rep->{redirect_uris}, [ { url => 'u' } ], 'a list that is not resolvable' );
  is( $rep->{provider}, 7, 'and the resolvable one' );
  is_deeply( $api->resolve_f( { provider => undef } )->get, { provider => undef }, 'undef is passed through' );

  my $before = { name => 'x', groups => ['staff'] };
  $api->resolve_f($before)->get;
  is_deeply( $before, { name => 'x', groups => ['staff'] }, 'the hash that was passed in is not changed' );
};

done_testing;
