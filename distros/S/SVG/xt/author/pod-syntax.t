use strict;
use Test::More;
use Test::Pod 1.00;

my @poddirs = qw( blib blib/lib/SVG);
all_pod_files_ok( all_pod_files( @poddirs ) );
