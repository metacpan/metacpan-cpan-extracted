package t::lib::Export;
use strict;
use warnings;

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/foo/;

sub foo { 1 }

1;

