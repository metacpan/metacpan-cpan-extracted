use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';

use TAP::Harness;
use TAP::Formatter::HTML;

# RT #82738: required TAP::Harness formatter method not available...
eval {
    TAP::Formatter::HTML->new->color(1);
};
my $e = $@;
ok(!$e, 'no error on color') || diag($e);
