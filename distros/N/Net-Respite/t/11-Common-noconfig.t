#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

{
    # Dummy config.pm to avoid trying to load
    $INC{"config.pm"} = undef;
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
ok($conf, "Missing config.pm does not crash $@");
isa_ok($conf, "HASH", '$obj->_configs');
ok($conf->{failed_load}, "Missing config.pm shows failure: ".$obj->json->encode($conf));
is($obj->xk, "unknown", "Missing config.pm default missing key");
