#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

{
    # Populate actual config:: namespace, but don't define anything.
    package config;
    $INC{"config.pm"} = "config.pm";
}

{
    package MyTestMod;
    use strict;
    use warnings;
    use base 'Net::Respite::Common';
    sub xk { return shift->_configs->{xxx_key} || "unknown" }
}

use_ok('Net::Respite::Common');
my $obj = MyTestMod->new;
ok($obj, 'inherit new: $obj=MyTestMod->new;');
isa_ok($obj, "Net::Respite::Common", '$obj');

my $conf = eval { $obj->_configs };
ok($conf, "Naked config.pm does not crash $@");
isa_ok($conf, "HASH", '$obj->_configs');
ok($conf->{failed_load}, "Naked config.pm shows failure: ".$obj->json->encode($conf));
is($obj->xk, "unknown", "Naked config.pm default missing key");
