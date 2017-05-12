package Site;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use Dancer2;
use Strehler::Dancer2::Plugin::EX;
use Strehler::Admin;
use Strehler::API;

set views => "$FindBin::Bin/testapp/views";

slug '/chapter/:slug', 'chapter', { 'item-type' => 'chapter', 'category' => 'dummy' };

1;
