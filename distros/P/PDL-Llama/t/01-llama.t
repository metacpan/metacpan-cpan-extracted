use strict;
use warnings;
use Test::More;

use_ok('PDL::Llama');

PDL::Llama::backend_init();
my $info = PDL::Llama::print_system_info();
ok(defined $info, 'print_system_info returns defined string');
ok(PDL::Llama::max_devices() >= 0, 'max_devices >= 0');
my $mmap = PDL::Llama::supports_mmap();
ok($mmap == 0 || $mmap == 1, 'supports_mmap returns boolean');
PDL::Llama::backend_free();

done_testing();
