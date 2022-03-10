#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Template::Plugin::Cache;

diag( "Testing Template::Plugin::Cache $Template::Plugin::Cache::VERSION, Perl $], $^X" );

pass( 'All modules loaded OK.' );

exit 0;
