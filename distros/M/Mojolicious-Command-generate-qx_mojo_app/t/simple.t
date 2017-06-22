use Test::More tests => 1;

use FindBin;
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';


use_ok 'Mojolicious::Command::generate::qx_mojo_app';

exit 0;
