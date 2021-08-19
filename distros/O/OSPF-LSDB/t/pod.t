use strict;
use warnings;

use Test::More;
use Test::Requires { 'Test::Pod' => '1.00' };

my @poddirs = qw( blib script doc );
all_pod_files_ok( all_pod_files( @poddirs ) );
