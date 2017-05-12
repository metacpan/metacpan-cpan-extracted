# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Plugin-Data-HTMLDumper.t'

#########################

use Test::More tests => 1; #qw( no_plan );

BEGIN { use_ok('Template::Plugin::Data::HTMLDumper') };


