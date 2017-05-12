use strict;
use warnings;
use Test::More tests => 1;
use Test::Moose;

use lib 't/lib';

use Affe;
meta_ok('Tiger', "namespaces aren't nested, although Tiger is loaded from within the Affe class definition");
