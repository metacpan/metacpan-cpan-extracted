#!perl

use strict;
use warnings;

use Test::More;
use Mojolicious::Plugin::NYTProf;

Mojolicious::Plugin::NYTProf::_find_nytprofhtml()
	|| plan skip_all => "Couldn't find nytprofhtml in PATH or in same location as $^X";

pass( "found nytprofhtml" );
done_testing();
