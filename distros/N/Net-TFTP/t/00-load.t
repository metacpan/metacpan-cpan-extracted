use Test::More;

use_ok Net::TFTP;

$tftp = Net::TFTP->new("some.host.name", BlockSize => 1024);
isa_ok($tftp, 'Net::TFTP', 'generated object');

can_ok($tftp, 'get');
can_ok($tftp, 'put');

done_testing();
