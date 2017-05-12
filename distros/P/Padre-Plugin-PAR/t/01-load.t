use strict;
use warnings;

use Test::More tests => 1;

BEGIN {use_ok('Padre::Plugin::PAR');}

use Padre;
diag "Padre::Plugin::PAR: $Padre::Plugin::PAR::VERSION";
diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();
 
