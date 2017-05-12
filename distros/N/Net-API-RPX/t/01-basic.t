#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;

use mocked [ 'LWP::UserAgent', 't/mock' ];

Basic: {
  use_ok('Net::API::RPX');

  can_ok( 'Net::API::RPX', qw(new api_key base_url ua) );
  can_ok( 'Net::API::RPX', qw(auth_info map unmap mappings) );
  can_ok( 'Net::API::RPX', qw(_agent_string) );

  dies_ok { Net::API::RPX->new() } 'api_key requred';
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );
  isa_ok( $rpx, 'Net::API::RPX' );

  isa_ok( $rpx->ua(), 'LWP::UserAgent' );
}

Agent_String: {
  my $rpx = Net::API::RPX->new(
    {
      api_key       => 'test',
      _agent_string => 'bob',
    }
  );

  is $rpx->ua->agent(), 'bob';
}

Auth_Info: {
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );

  throws_ok { $rpx->auth_info( {} ); } qr{Token is required}, 'token required';

  $HTTP::Response::CONTENT = '{ "stat": "ok" }';
  $rpx->auth_info( { token => 'foo' } );
  is $LWP::UserAgent::LAST_POST_URL, 'https://rpxnow.com/api/v2/auth_info', 'auth_info correct url';
  is_deeply $LWP::UserAgent::LAST_POST_ARGUMENTS,
    {
    format => 'json',
    apiKey => 'test',
    token  => 'foo',
    },
    'correct arguments';
}

Map: {
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );

  throws_ok { $rpx->map( {} ) } qr{Identifier is required}, 'Identifier required';
  throws_ok { $rpx->map( { identifier => 'fred' } ) } qr{Primary Key is required}, 'Primary Key required';

  $HTTP::Response::CONTENT = '{ "stat": "ok" }';
  $rpx->map( { identifier => 'fred', primary_key => 12 } );
  is $LWP::UserAgent::LAST_POST_URL, 'https://rpxnow.com/api/v2/map', 'map correct url';
  is_deeply $LWP::UserAgent::LAST_POST_ARGUMENTS,
    {
    format     => 'json',
    apiKey     => 'test',
    identifier => 'fred',
    primaryKey => 12
    },
    'correct arguments';
}

Unmap: {
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );

  throws_ok { $rpx->unmap( {} ) } qr{Identifier is required}, 'Identifier required';
  throws_ok { $rpx->unmap( { identifier => 'fred' } ) } qr{Primary Key is required}, 'Primary Key required';

  $HTTP::Response::CONTENT = '{ "stat": "ok" }';
  $rpx->unmap( { identifier => 'fred', primary_key => 12 } );
  is $LWP::UserAgent::LAST_POST_URL, 'https://rpxnow.com/api/v2/unmap', 'unmap correct url';
  is_deeply $LWP::UserAgent::LAST_POST_ARGUMENTS,
    {
    format     => 'json',
    apiKey     => 'test',
    identifier => 'fred',
    primaryKey => 12
    },
    'correct arguments';
}

Mappings: {
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );

  throws_ok { $rpx->mappings( {} ) } qr{Primary Key is required}, 'Primary Key required';

  $HTTP::Response::CONTENT = '{ "stat": "ok" }';
  $rpx->mappings( { primary_key => 4 } );
  is $LWP::UserAgent::LAST_POST_URL, 'https://rpxnow.com/api/v2/mappings', 'mappings correct url';
  is_deeply $LWP::UserAgent::LAST_POST_ARGUMENTS,
    {
    format     => 'json',
    apiKey     => 'test',
    primaryKey => 4,
    },
    'correct arguments';
}

Failure_Scenarios: {
  my $rpx = Net::API::RPX->new( { api_key => 'test' } );

  {
    local $HTTP::Response::SUCCESS = 0;
    local $HTTP::Response::STATUS  = '500 the tubes were clogged';

    throws_ok {
      $rpx->auth_info( { token => 'boo' } )
    }
    qr{Could not contact RPX: 500 the tubes were clogged}, 'LWP failure handled';
  }

  local $HTTP::Response::CONTENT = '{ "stat": "fail", "err": { "code": "2", "msg": "server went pop" } }';
  throws_ok {
    $rpx->auth_info( { token => 'yelp' } )
  }
  qr{RPX returned error of type 'Data not found' with message: server went pop}, 'RPX failure handled';
}

