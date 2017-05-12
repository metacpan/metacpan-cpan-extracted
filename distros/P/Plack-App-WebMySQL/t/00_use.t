use strict;
use warnings;
use Test::More;
use lib qw(lib);
plan(tests => 4);
use_ok("Plack::App::WebMySQL");
use_ok("Plack::App::WebMySQL::General");
use_ok("Plack::App::WebMySQL::Key");
use_ok("Plack::App::WebMySQL::Sql");
