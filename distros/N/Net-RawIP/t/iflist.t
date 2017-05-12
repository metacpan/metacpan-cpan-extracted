#!perl
use strict;
use warnings;
use Data::Dumper    qw(Dumper);
use English         qw(-no_match_vars);
use Test::More;
use Net::RawIP;


plan tests => my $tests;

my $loopback = undef;

BEGIN { $tests += 3 } {
    my $list = ifaddrlist();
    is( ref($list), 'HASH', 'ifaddrlist() return HASH ref');

    ($loopback) = grep { exists $list->{$_} } qw(lo lo0);
    ok(exists $list->{$loopback}, "loopback interface is $loopback");
    is($list->{$loopback}, '127.0.0.1', "loopback interface is 127.0.0.1");
}

BEGIN { $tests += 4 } SKIP: {
    eval { rdev("127.0.0.1") };
    skip "rdev() is not implemented on this system", 4
        if $@ =~ /rdev\(\) is not implemented on this system/;
    
    is( rdev('127.0.0.1'), $loopback, "rdev('127.0.0.1') => $loopback" );
    is( rdev('localhost'), $loopback, "rdev('localhost') => $loopback" );

    my $r = eval { rdev('ab cd') };
    like( $@, qr{host_to_ip: failed}, "rdev('ab cd') => undef" );

    # this test will fail if there is not network connection
    $r = rdev('cisco.com');
    ok( $r, "rdev('cisco.com') => $r" );
}

