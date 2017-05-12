#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 39;

BEGIN {
    use_ok('Carp');
    use_ok('Net::OBEX::Packet::Request::Base');
    use_ok('Net::OBEX::Packet::Request::Abort');
    use_ok('Net::OBEX::Packet::Request::Connect');
    use_ok('Net::OBEX::Packet::Request::Disconnect');
    use_ok('Net::OBEX::Packet::Request::Get');
    use_ok('Net::OBEX::Packet::Request::Put');
    use_ok('Net::OBEX::Packet::Request::SetPath');
	use_ok('Net::OBEX::Packet::Request');
}

diag( "Testing Net::OBEX::Packet::Request $Net::OBEX::Packet::Request::VERSION, Perl $], $^X" );

use Net::OBEX::Packet::Request;
my $pack = Net::OBEX::Packet::Request->new;
isa_ok($pack, 'Net::OBEX::Packet::Request');
can_ok($pack, qw(_make_connect _make_disconnect _make_abort
 _make_get _make_put _make_setpath make new));

my %packets;

for ( qw(connect disconnect abort get put setpath) ) {
    $packets{ $_ } = $pack->make( packet => $_ );
}

use Net::OBEX::Packet::Request::Abort;
use Net::OBEX::Packet::Request::Connect;
use Net::OBEX::Packet::Request::Disconnect;
use Net::OBEX::Packet::Request::Get;
use Net::OBEX::Packet::Request::Put;
use Net::OBEX::Packet::Request::SetPath;

my %objs;
$objs{abort} = Net::OBEX::Packet::Request::Abort->new;
$objs{connect} = Net::OBEX::Packet::Request::Connect->new;
$objs{disconnect} = Net::OBEX::Packet::Request::Disconnect->new;
$objs{get} = Net::OBEX::Packet::Request::Get->new;
$objs{put} = Net::OBEX::Packet::Request::Put->new;
$objs{setpath} = Net::OBEX::Packet::Request::SetPath->new;

isa_ok($objs{abort}, 'Net::OBEX::Packet::Request::Abort');
isa_ok($objs{connect}, 'Net::OBEX::Packet::Request::Connect');
isa_ok($objs{disconnect}, 'Net::OBEX::Packet::Request::Disconnect');
isa_ok($objs{get}, 'Net::OBEX::Packet::Request::Get');
isa_ok($objs{put}, 'Net::OBEX::Packet::Request::Put');
isa_ok($objs{setpath}, 'Net::OBEX::Packet::Request::SetPath');

for ( qw(connect disconnect abort get put setpath) ) {
    can_ok( $objs{$_}, qw(headers raw new make) );
}

for ( qw(get put) ) {
    can_ok($objs{$_}, qw(is_final));
}

can_ok( $objs{connect}, qw( mtu version flags ));
can_ok( $objs{setpath}, qw( do_up no_create constants ));

my %bytes = (
    connect => '80000710001000',
    disconnect  => '810003',
    abort       => 'ff0003',
    get         => '030003',
    put         => '020003',
    setpath     => '8500050200',
);

for ( qw(connect disconnect abort get put setpath) ) {
    my $raw = unpack 'H*', $packets{$_};
    is(
        $raw,
        $bytes{$_},
        "$_ packet raw bytes",
    );

    my $raw2 = $objs{$_}->make;
    is(
        $packets{$_},
        $raw2,
        "makes should be the same for $_ packet",
    );
}

