#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN {
    use_ok('Carp');
    use_ok('Net::OBEX::Packet::Headers');
    use_ok('Net::OBEX::Response::Connect');
    use_ok('Net::OBEX::Response::Generic');
	use_ok('Net::OBEX::Response');
}

diag( "Testing Net::OBEX::Response $Net::OBEX::Response::VERSION, Perl $], $^X" );

use Net::OBEX::Response;
use Net::OBEX::Response::Connect;
use Net::OBEX::Response::Generic;

my $res = Net::OBEX::Response->new;
isa_ok( $res, 'Net::OBEX::Response');
can_ok( $res, qw( new parse parse_sock error obj_connect  obj_generic  obj_head));

my $connect_raw = pack 'H*', 'a0001f10001406';
my $raw         = pack 'H*', 'a00003';

my $conn_ref = $res->parse( $connect_raw, 1 );
my $res_ref  = $res->parse( $raw );

my $VAR1 = {
          'flags' => '00000000',
          'packet_length' => 31,
          'obex_version' => '00010000',
          'response_code' => 200,
          'headers_length' => 24,
          'response_code_meaning' => 'OK, Success',
          'mtu' => 5126
        };
my $VAR2 = {
          'packet_length' => 3,
          'response_code' => 200,
          'headers_length' => 0,
          'response_code_meaning' => 'OK, Success'
        };

is_deeply( $conn_ref, $VAR1 );
is_deeply( $res_ref,  $VAR2 );

my %objs = (
    connect => Net::OBEX::Response::Connect->new,
    generic => Net::OBEX::Response::Generic->new,
);
isa_ok($objs{connect}, 'Net::OBEX::Response::Connect');
isa_ok($objs{generic}, 'Net::OBEX::Response::Generic');

for ( qw( connect generic ) ) {
    can_ok( $objs{$_}, qw(new parse_info code_meaning packet info
                            headers_length _make_response_codes));
}

my $connect_parse_ref = $objs{connect}->parse_info($connect_raw);
my $parse_ref = $objs{generic}->parse_info($raw);

is_deeply( $conn_ref, $connect_parse_ref);
is_deeply( $res_ref, $parse_ref );
