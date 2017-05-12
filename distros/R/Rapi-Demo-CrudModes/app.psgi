use FindBin;
use lib "$FindBin::Bin/lib";

use Rapi::Demo::CrudModes;
my $app = Rapi::Demo::CrudModes->new;

# Plack/PSGI app:
$app->to_app
