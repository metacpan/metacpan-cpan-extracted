#!/usr/bin/perl

use Test::More tests => 18;
use Data::Dumper;
use lib qw(../lib);

BEGIN { use_ok( 'Nagios::NRPE::Packet' ); }

use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3
			    NRPE_PACKET_VERSION_2
			    NRPE_PACKET_VERSION_1
			    NRPE_PACKET_QUERY
			    NRPE_PACKET_RESPONSE
			    MAX_PACKETBUFFER_LENGTH
			    MAX_COMMAND_ARGUMENTS
			    NRPE_HELLO_COMMAND
			    DEFAULT_SOCKET_TIMEOUT
			    DEFAULT_CONNECTION_TIMEOUT
			    STATE_UNKNOWN
			    STATE_CRITICAL
			    STATE_WARNING
			    STATE_OK);

my $packet = Nagios::NRPE::Packet->new();

ok(defined($packet), 'constructor works');
ok(ref $packet eq 'Nagios::NRPE::Packet', 'ref correct');

ok(NRPE_PACKET_VERSION_3 eq 3,'NRPE_PACKET_VERSION_3 correct value');
ok(NRPE_PACKET_VERSION_2 eq 2,'NRPE_PACKET_VERSION_2 correct value');
ok(NRPE_PACKET_VERSION_1 eq 1,'NRPE_PACKET_VERSION_1 correct value');
ok(NRPE_PACKET_QUERY eq     1,'NRPE_PACKET_QUERY correct value');
ok(NRPE_PACKET_RESPONSE eq  2,'NRPE_PACKET_RESPONSE correct value');


ok(MAX_PACKETBUFFER_LENGTH eq 1024,'MAX_PACKETBUFFER_LENGTH correct value');
ok(MAX_COMMAND_ARGUMENTS eq 16,'MAX_COMMAND_ARGUMENTS correct value');

ok(NRPE_HELLO_COMMAND eq "_NRPE_CHECK",'NRPE_HELLO_COMMAND correct value');

ok(STATE_UNKNOWN eq 3,'STATE_UNKNOWN correct value');
ok(STATE_CRITICAL eq 2,'STATE_CRITICAL correct value');
ok(STATE_WARNING eq 1, 'STATE_WARNING correct value');

ok(STATE_OK eq 0, 'STATE_OK correct value');

my $assembly = $packet->assemble(type => NRPE_PACKET_QUERY, check => "check_load", version => NRPE_PACKET_VERSION_2);
my $deassembly = $packet->deassemble($assembly);

is($deassembly->{packet_type}, NRPE_PACKET_QUERY);
is($deassembly->{packet_version}, NRPE_PACKET_VERSION_2);
is($deassembly->{buffer}, "check_load");

