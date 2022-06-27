use strict;
use warnings;

use Test::More;
use Test::Requires 'Mojo::Base';

use FindBin qw($Bin);
use lib "$Bin/lib";
use Tester::MojoBase;
use Tester;

Tester::run_tests( Tester::MojoBase->new );

done_testing;
