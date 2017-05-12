use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use Test::More tests => 4;
use Test::Mojo;

use_ok 'QxExample';

$ENV{QX_SRC_MODE} =1;
$ENV{QX_SRC_PATH} = '../example/';

my $t = Test::Mojo->new('QxExample');

$t->get_ok('/root/index.html')
  ->content_like(qr/HelloWorld/)
  ->status_is(200);

exit 0;
