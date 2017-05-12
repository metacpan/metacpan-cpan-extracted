use strict;
use warnings;
use Test::More;
use lib qw(lib);
use Plack::App::WebMySQL;
plan(tests => 1);

my $app = Plack::App::WebMySQL->new();
isa_ok($app, 'Plack::Builder');