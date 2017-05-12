#!/usr/bin/perl

# Test attribute unsetting attributes with ASCII and non-ASCII (8-bit) values

# $Id: attrunset.t 81 2007-04-26 20:25:21Z lem $


use IO::File;
use Test::More qw/no_plan/;
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	integer
ATTRIBUTE	Reply-Message		18	string
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

my $d = new Net::Radius::Dictionary "dict.$$";
isa_ok($d, 'Net::Radius::Dictionary');

# Build a request and test it is ok
my $p = new Net::Radius::Packet $d;
isa_ok($p, 'Net::Radius::Packet');
$p->set_identifier(42);
$p->set_authenticator("\x66" x 16);
$p->set_code("Access-Accept");
$p->set_attr('Reply-Message' => 'Hello World 1');

is($p->attr('Reply-Message'), 'Hello World 1', 'ASCII Reply-Message loaded');

$p->unset_attr('Reply-Message', $p->attr('Reply-Message'));
is($p->attr('Reply-Message'), undef, 'ASCII Reply-Message deleted');

$p->set_attr('Reply-Message' => '¡Hola Mundo!');
is($p->attr('Reply-Message'), '¡Hola Mundo!', 'UTF-8 Reply-Message loaded');

$p->unset_attr('Reply-Message', $p->attr('Reply-Message'));
is($p->attr('Reply-Message'), undef, 'UTF-8 Reply-Message loaded');

$p->set_attr('Reply-Message' => "\xde\xad\x00\xbe\xef");
is($p->attr('Reply-Message'), "\xde\xad\x00\xbe\xef", 
   '8-bit Reply-Message present');

$p->unset_attr('Reply-Message', $p->attr('Reply-Message'));
is($p->attr('Reply-Message'), undef, '8-bit Reply-Message deleted');
