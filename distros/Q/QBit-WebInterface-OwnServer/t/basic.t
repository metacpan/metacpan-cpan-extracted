use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";

use Test::More;

use qbit;

use TestWebInterface;

my $server = new_ok('TestWebInterface');

is(QBit::WebInterface::OwnServer::__normalize_path('/../asb/ss/../../'), '/../', 'Checking path normalization');
is(
    $server->_is_static("/qbit/css/qbit.css"),
    "$server->{'__ORIG_OPTIONS__'}{'FrameworkPath'}QBit/data/css/qbit.css",
    'Checking get real file path'
  );

done_testing();
