use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example';

use Test::More tests => 2;
use Test::Mojo;


use_ok 'Mojolicious::Plugin::ReverseProxy';
use_ok 'CookieWrapper';

my $t = Test::Mojo->new('CookieWrapper');

exit 0;
