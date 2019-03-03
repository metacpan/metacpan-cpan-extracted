#!perl

use strict;
use warnings;
use Test::More tests => 2;

use File::Basename qw(dirname);
use lib dirname(__FILE__)."/lib"; # t/lib

require Module::Lazy;

Module::Lazy->import( "Module::Lazy::_::test::sample" );
is $Module::Lazy::_::test::sample::VERSION, undef, "module not loaded yet";

Module::Lazy->unimport;
is $Module::Lazy::_::test::sample::VERSION, 42, "module loaded now";



