use strict;
use warnings;

use Test::More tests => 1;
use Sub::Name;

my $sub = sub { (caller(0))[3] };
subname "foo::quz'bar::baz", $sub;

# in 0.16, this was foo::quz::ba::baz
is(
    $sub->(),
    "foo::quz::bar::baz",
    'correctly parsed single quote from name where the last separator is ::',
);
