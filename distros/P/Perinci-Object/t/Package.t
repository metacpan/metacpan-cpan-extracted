#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use Perinci::Object;

my $ripkg = ripkg { v=>1.1 };

is($ripkg->type, "package", "type");
is($ripkg->v, 1.1, "v");

done_testing();
