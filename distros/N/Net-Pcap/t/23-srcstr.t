#!perl -T
use strict;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

plan skip_all => "pcap_createsrcstr() is not available" unless is_available('pcap_createsrcstr');
plan tests => 18;

my $has_test_exception = eval "use Test::Exception; 1";

my($src,$r,$err) = ('',0,'');
my($type,$host,$port,$name) = ('rpcap', 'fangorn', 12345, 'eth0');

# Testing error messages
SKIP: {
    skip "Test::Exception not available", 9 unless $has_test_exception;

    # createsrcstr() errors
    throws_ok(sub {
        Net::Pcap::createsrcstr()
    }, '/^Usage: Net::Pcap::createsrcstr\(source, type, host, port, name, err\)/', 
       "calling createsrcstr() with no argument");

    throws_ok(sub {
        Net::Pcap::createsrcstr(0, 0, 0, 0, 0, 0)
    }, '/^arg1 not a reference/', 
       "calling createsrcstr() with incorrect argument type for arg1");

    throws_ok(sub {
        Net::Pcap::createsrcstr(\$src, 0, 0, 0, 0, 0)
    }, '/^arg6 not a hash ref/', 
       "calling createsrcstr() with incorrect argument type for arg6");

    # parsesrcstr() errors
    throws_ok(sub {
        Net::Pcap::parsesrcstr()
    }, '/^Usage: Net::Pcap::parsesrcstr\(source, type, host, port, name, err\)/', 
       "calling parsesrcstr() with no argument");

    throws_ok(sub {
        Net::Pcap::parsesrcstr(0, 0, 0, 0, 0, 0)
    }, '/^arg2 not a reference/', 
       "calling parsesrcstr() with incorrect argument type for arg2");

    throws_ok(sub {
        Net::Pcap::parsesrcstr(0, \$type, 0, 0, 0, 0)
    }, '/^arg3 not a reference/', 
       "calling parsesrcstr() with incorrect argument type for arg3");

    throws_ok(sub {
        Net::Pcap::parsesrcstr(0, \$type, \$host, 0, 0, 0)
    }, '/^arg4 not a reference/', 
       "calling parsesrcstr() with incorrect argument type for arg4");

    throws_ok(sub {
        Net::Pcap::parsesrcstr(0, \$type, \$host, \$port, 0, 0)
    }, '/^arg5 not a reference/', 
       "calling parsesrcstr() with incorrect argument type for arg5");

    throws_ok(sub {
        Net::Pcap::parsesrcstr(0, \$type, \$host, \$port, \$name, 0)
    }, '/^arg6 not a reference/', 
       "calling parsesrcstr() with incorrect argument type for arg6");

}

$r = eval { createsrcstr(\$src, $type, $host, $port, $name, \$err) };
is( $@, '', "createsrcstr() " );
is( $r, 0, " - should return zero: $r" );
is( $src, "$type\://$host\:$port/$name", " - checking created source string" );

my($parsed_type,$parsed_host,$parsed_port,$parsed_name) = ('','','','');
$r = eval { parsesrcstr($src, \$parsed_type, \$parsed_host, \$parsed_port, \$parsed_name, \$err) };
is( $@, '', "parsesrcstr() " );
is( $r, 0, " - should return zero: $r" );
is( $parsed_type, $type, " - checking parsed type" );
is( $parsed_host, $host, " - checking parsed host" );
is( $parsed_port, $port, " - checking parsed port" );
is( $parsed_name, $name, " - checking parsed name" );

