use Test::More;
use Test::Exception;
use Test::Warnings;

use Sys::CpuLoad qw/ load /;

no warnings 'once';

$Sys::CpuLoad::LOAD = 'uptimr';

throws_ok { load() } qr/^Unknown function: uptimr /, 'load dies';

done_testing;
