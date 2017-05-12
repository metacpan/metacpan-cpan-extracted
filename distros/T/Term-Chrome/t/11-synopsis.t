#!perl

use strict;
use warnings;

# Only for automated testing (Travis, CPAN testers), not for users
use Test::Is 'perl v5.10', 'extended';

use Test::Requires 'Test::Synopsis' => '0.14';

all_synopsis_ok;
