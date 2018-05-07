#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;

use lib '../lib', 'lib';

use_ok('SMB::DCERPC');

my $server_dcerpc = SMB::DCERPC->new(name => 'srvsvc');
my $client_dcerpc = SMB::DCERPC->new(name => 'srvsvc');

my ($status, $buffer);
my $retinfo = {};
sub SUCCESS () { SMB::STATUS_SUCCESS() };

($buffer, $status) = $client_dcerpc->generate_bind_request;
is($status, SUCCESS, "status after generate_bind_request");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_bind_request");

is($server_dcerpc->process_bind_request($buffer), SUCCESS, "status after process_bind_request");

($buffer, $status) = $server_dcerpc->generate_bind_ack_response;
is($status, SUCCESS, "status after generate_bind_ack_response");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_bind_ack_response");

is($client_dcerpc->process_bind_ack_response($buffer), SUCCESS, "status after process_bind_ack_response");

($buffer, $status) = $client_dcerpc->generate_rpc_request('NetShareGetInfo', share_name => 'usersshare');
is($status, SUCCESS, "status after generate_rpc_request");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_rpc_request");

is($server_dcerpc->process_rpc_request($buffer), SUCCESS, "status after process_rpc_request");
is($server_dcerpc->requested_opinfo->{share_name}, "usersshare", "share_name after process_rpc_response");

($buffer, $status) = $server_dcerpc->generate_rpc_response;
is($status, SUCCESS, "status after generate_rpc_response");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_rpc_response");

is($client_dcerpc->process_rpc_response($buffer, $retinfo), SUCCESS, "status after process_rpc_response");
is($retinfo->{share_name}, "usersshare", "share_name after process_rpc_response");

($buffer, $status) = $client_dcerpc->generate_packet('NetShareGetInfo', share_name => 'public');
is($status, SUCCESS, "status after generate_packet (generate_rpc_request)");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_rpc_request");

is($server_dcerpc->process_packet($buffer), SUCCESS, "status after process_packet (process_rpc_request)");
is($server_dcerpc->requested_opinfo->{share_name}, "public", "share_name after process_packet (process_rpc_response)n");

($buffer, $status) = $server_dcerpc->generate_packet;
is($status, SUCCESS, "status after generate_packet (generate_rpc_response)");
cmp_ok(length($buffer // ''), ">", 0, "buffer after generate_packet (generate_rpc_response)");

is($client_dcerpc->process_packet($buffer, $retinfo), SUCCESS, "status after process_packet (process_rpc_response)");
is($retinfo->{share_name}, "public", "share_name after process_packet (process_rpc_response)");

