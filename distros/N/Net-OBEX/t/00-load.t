#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok('Carp');
    use_ok('Socket::Class');
    use_ok('IO::Handle');
    use_ok('Net::OBEX::Packet::Request');
    use_ok('Net::OBEX::Response');
    use_ok('Net::OBEX::Packet::Headers');
    use_ok('Class::Data::Accessor');
    use_ok('Devel::TakeHashArgs');
	use_ok('Net::OBEX');
}

diag( "Testing Net::OBEX $Net::OBEX::VERSION, Perl $], $^X" );

use Net::OBEX;
my $o = Net::OBEX->new;
isa_ok( $o, 'Net::OBEX');
can_ok($o, qw(new connect disconnect set_path get close response sock error
connection_id obj_res obj_req obj_head _set_error put code status success
mtu));

