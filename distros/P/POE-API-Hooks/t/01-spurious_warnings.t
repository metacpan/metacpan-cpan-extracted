
use Test::More tests => 1;

$SIG{__WARN__} = sub { die shift };
eval q|
use POE;
use POE::API::Hooks;
|;

is($@,'','Module load + POE - exceptions and warning check');
