
use strict;
use warnings;

use Test::More tests => 62;
use mocked [ 'LWP::UserAgent', 't/mock' ];
use Net::API::RPX;
use Data::Dump qw( dump );

sub capture(&) {
  my ($code) = shift;
  my ( $result, $evalerror ) = ( 'fail', );
  local $@;
  eval { $code->(); $result = 'test_success' };
  $evalerror = $@;
  if ( defined $result && $result eq 'test_success' ) {
    return ( 1, undef );
  }
  return ( 0, $evalerror );
}
Auth_Info: {
  my ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->auth_info( {} );
  };
  ok( !$result, 'expected auth_info fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Token is required/, '->message' );
  is( $error->method_name,        '->auth_info',   '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'token',         '->required_parameter' );

  # 7;
  ( $result, $error ) = capture {
    $HTTP::Response::CONTENT = '{ "stat": "ok" }';
    Net::API::RPX->new( { api_key => 'test' } )->auth_info( { token => 'foo' } );
  };
  ok( $result, 'no auth_info fail' );

  # 8
}

Map: {

  my ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->map( {} );
  };
  ok( !$result, 'expected map fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Identifier is required/, '->message' );
  is( $error->method_name,        '->map',         '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'identifier',    '->required_parameter' );
  ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->map( { identifier => 'fred' } );
  };
  ok( !$result, 'expected map fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Primary Key is required/, '->message' );
  is( $error->method_name,        '->map',         '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'primary_key',   '->required_parameter' );
  ( $result, $error ) = capture {
    $HTTP::Response::CONTENT = '{ "stat": "ok" }';
    Net::API::RPX->new( { api_key => 'test' } )->map( { identifier => 'fred', primary_key => 12 } );
  };
  ok( $result, 'map shouldn\'t fail' );

}

Unmap: {

  my ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->unmap( {} );
  };
  ok( !$result, 'expected unmap fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Identifier is required/, '->message' );
  is( $error->method_name,        '->unmap',       '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'identifier',    '->required_parameter' );
  ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->unmap( { identifier => 'fred' } );
  };
  ok( !$result, 'expected unmap fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Primary Key is required/, '->message' );
  is( $error->method_name,        '->unmap',       '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'primary_key',   '->required_parameter' );
  ( $result, $error ) = capture {
    $HTTP::Response::CONTENT = '{ "stat": "ok" }';
    Net::API::RPX->new( { api_key => 'test' } )->unmap( { identifier => 'fred', primary_key => 12 } );
  };
  ok( $result, 'unmap shouldn\'t fail' );

}

Mappings: {
  my ( $result, $error ) = capture {
    Net::API::RPX->new( { api_key => 'test' } )->mappings( {} );
  };
  ok( !$result, 'expected mappings fail' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Usage' );
  like( $error->message, qr/^Primary Key is required/, '->message' );
  is( $error->method_name,        '->mappings',    '->method_name' );
  is( $error->package,            'Net::API::RPX', '->package' );
  is( $error->required_parameter, 'primary_key',   '->required_parameter' );
  ( $result, $error ) = capture {
    $HTTP::Response::CONTENT = '{ "stat": "ok" }';
    Net::API::RPX->new( { api_key => 'test' } )->mappings( { primary_key => 12 } );
  };
  ok( $result, 'mappings shouldn\'t fail' );

}

FailureScenarios: {
  my ( $result, $error ) = capture {
    local $HTTP::Response::SUCCESS = 0;
    local $HTTP::Response::STATUS  = '500 the tubes were clogged';

    Net::API::RPX->new( { api_key => 'test' } )->auth_info( { token => 'boo' } );

  };

  ok( !$result, 'auth_info should fail due to tubes being clogged' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Network' );
  is( $error->message, 'Could not contact RPX: 500 the tubes were clogged', '->message' );
  is( $error->status_line, '500 the tubes were clogged', '->status_line' );
  isa_ok( $error->ua_result, 'HTTP::Response' );
  ( $result, $error ) = capture {
    local $HTTP::Response::CONTENT = '{ "stat": "fail", "err": { "code": "2", "msg": "server went pop" } }';
    Net::API::RPX->new( { api_key => 'test' } )->auth_info( { token => 'yelp' } );
  };
  ok( !$result, 'auth_info should send a server error' );
  isa_ok( $error, 'Net::API::RPX::Exception' );
  isa_ok( $error, 'Net::API::RPX::Exception::Service' );

  is_deeply( $error->data, { err => { code => 2, msg => "server went pop" }, stat => "fail" }, '->data' );
  is( $error->message, 'RPX returned error of type \'Data not found\' with message: server went pop', '->message' );
  is_deeply( $error->rpx_error, { code => 2, msg => "server went pop" }, '->rpx_error' );
  is( $error->rpx_error_code,             2,                 '->rpx_error_code' );
  is( $error->rpx_error_message,          'server went pop', '->rpx_error_message' );
  is( $error->status,                     'fail',            '->status' );
  is( $error->rpx_error_code_description, 'Data not found',  '->rpx_error_code_description' );

}
