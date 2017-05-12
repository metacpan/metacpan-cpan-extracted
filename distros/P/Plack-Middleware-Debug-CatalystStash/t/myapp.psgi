use strict;
use warnings;
use FindBin qw($Bin);

use lib "${Bin}/lib";

use MyApp;
my $app = MyApp->apply_default_middlewares( MyApp->psgi_app );

$app;
