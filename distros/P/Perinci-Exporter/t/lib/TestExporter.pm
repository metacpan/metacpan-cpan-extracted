package TestExporter;

use strict;
use warnings;
use Perinci::Exporter;

our @EXPORT    = qw(bar);
our @EXPORT_OK = qw(baz);

our %SPEC;

$SPEC{foo} = {
    v => 1.1,
    result_naked => 1,
};
sub foo { "foo" }

$SPEC{bar} = {
    v => 1.1,
};
sub bar { [200, "OK", "bar"] }

$SPEC{baz} = {
    v => 1.1,
};
sub baz { [200, "OK", "baz"] }

1;
