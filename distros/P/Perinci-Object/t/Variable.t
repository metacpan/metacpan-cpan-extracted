#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use Perinci::Object;

my $rivar = rivar { v=>1.1 };

is($rivar->type, "variable", "type");
is($rivar->v, 1.1, "v");

done_testing();
