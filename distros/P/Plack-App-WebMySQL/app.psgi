use strict;
use warnings;
use lib "lib";
use Plack::App::WebMySQL;

my $app = Plack::App::WebMySQL->new()->to_app;
