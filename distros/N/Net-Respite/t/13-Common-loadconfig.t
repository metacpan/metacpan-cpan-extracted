#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

{
    # Test &config::load() method
    package config;
    sub load {
        return { xxx_key => "Used load method" };
    }
    $INC{"config.pm"} = "config.pm";
}

{
    package MyTestMod;
    use base 'Net::Respite::Common';

    sub xk { return shift->_configs->{xxx_key} || "unknown" }
}

use_ok('Net::Respite::Common');
my $obj = MyTestMod->new;
ok($obj, 'inherit new: $obj=MyTestMod->new;');
isa_ok($obj, "Net::Respite::Common", '$obj');

my $conf = eval { $obj->_configs };
ok($conf, "Using &config::load does not crash $@");
isa_ok($conf, "HASH", '$obj->_configs');
ok(!$conf->{failed_load}, '&load not failed: '.$obj->json->encode($conf));
like($obj->xk, qr/Used/, '&load found key: '.$obj->xk);
