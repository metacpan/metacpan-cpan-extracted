use strict;
use warnings;

use Test::More tests => 1;


BEGIN { use_ok('Padre::Plugin::InstallPARDist') }
require Padre;

diag "Padre::Plugin::InstallPARDist: $Padre::Plugin::InstallPARDist::VERSION";
diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();
