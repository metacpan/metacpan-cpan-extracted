# $Id: 22_pod.t 326 2006-05-30 18:20:05Z tinita $
use strict;
use Test::More;
eval "use
Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib );
all_pod_files_ok( all_pod_files( @poddirs ) );

