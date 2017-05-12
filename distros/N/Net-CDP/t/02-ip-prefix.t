use Test::More tests => 27;

BEGIN { use_ok('Net::CDP::IPPrefix'); }

my $ip_prefix = new Net::CDP::IPPrefix('127.128.129.130/8');
isa_ok($ip_prefix, 'Net::CDP::IPPrefix', 'IP prefix #1');

is($ip_prefix->cidr,    '127.0.0.0/8', 'IP prefix #1: cidr is valid');
is($ip_prefix->network, '127.0.0.0',   'IP prefix #1: network is valid');
is($ip_prefix->mask,    '255.0.0.0',   'IP prefix #1: mask is valid');
is($ip_prefix->length,  8,             'IP prefix #1: length is valid');

$ip_prefix = new Net::CDP::IPPrefix('127.128.129.130', 8);
isa_ok($ip_prefix, 'Net::CDP::IPPrefix', 'IP prefix #2');

is($ip_prefix->cidr,    '127.0.0.0/8', 'IP prefix #2: cidr is valid');
is($ip_prefix->network, '127.0.0.0',   'IP prefix #2: network is valid');
is($ip_prefix->mask,    '255.0.0.0',   'IP prefix #2: mask is valid');
is($ip_prefix->length,  8,             'IP prefix #2: length is valid');

$ip_prefix = new Net::CDP::IPPrefix('127.128.129.130/255.0.0.0');
isa_ok($ip_prefix, 'Net::CDP::IPPrefix', 'IP prefix #3');

is($ip_prefix->cidr,    '127.0.0.0/8', 'IP prefix #3: cidr is valid');
is($ip_prefix->network, '127.0.0.0',   'IP prefix #3: network is valid');
is($ip_prefix->mask,    '255.0.0.0',   'IP prefix #3: mask is valid');
is($ip_prefix->length,  8,             'IP prefix #3: length is valid');

$ip_prefix = new Net::CDP::IPPrefix('127.128.129.130', '255.0.0.0');
isa_ok($ip_prefix, 'Net::CDP::IPPrefix', 'IP prefix #4');

is($ip_prefix->cidr,    '127.0.0.0/8', 'IP prefix #4: cidr is valid');
is($ip_prefix->network, '127.0.0.0',   'IP prefix #4: network is valid');
is($ip_prefix->mask,    '255.0.0.0',   'IP prefix #4: mask is valid');
is($ip_prefix->length,  8,             'IP prefix #4: length is valid');

my $cloned = clone $ip_prefix;
isa_ok($cloned, 'Net::CDP::IPPrefix', 'Cloned IP prefix');
bless $ip_prefix, '_Fake';
bless $cloned, '_Fake';
isnt(int($cloned), int($ip_prefix), 'Cloned IP prefix: memory location is different from original');
bless $ip_prefix, 'Net::CDP::IPPrefix';
bless $cloned, 'Net::CDP::IPPrefix';

is($cloned->cidr,    $ip_prefix->cidr,    'Cloned IP prefix: cidr is identical to original');
is($cloned->network, $ip_prefix->network, 'Cloned IP prefix: network is identical to original');
is($cloned->mask,    $ip_prefix->mask,    'Cloned IP prefix: mask is identical to original');
is($cloned->length,  $ip_prefix->length,  'Cloned IP prefix: length is identical to original');
