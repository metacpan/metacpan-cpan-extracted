use strict;
use warnings;
use Test::More;
use Test::Exception;

use MooseX::Types::Varchar qw/Varchar/;

lives_ok { Varchar[20] };
dies_ok { Varchar['flibble'] };

done_testing;

