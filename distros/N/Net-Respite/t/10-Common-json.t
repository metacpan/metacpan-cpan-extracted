#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

# Test proper inheritance
{
    package MyTestMod;
    use strict;
    use warnings;
    use base 'Net::Respite::Common';
    sub enc { return shift->json->encode(shift) }
}

use_ok('Net::Respite::Common');
my $obj = MyTestMod->new;
ok($obj, 'inherit new: $obj=MyTestMod->new;');
isa_ok($obj, "HASH", '$obj');
isa_ok($obj, "MyTestMod", '$obj');
isa_ok($obj, "Net::Respite::Common", '$obj');

my $json = $obj->json;
ok($json, "inherit json");
isa_ok($json, "JSON", '$obj->json');

my $coded = $obj->enc({n=>"v"});
like($coded, qr/\{/, "JSON behaves: $coded");
