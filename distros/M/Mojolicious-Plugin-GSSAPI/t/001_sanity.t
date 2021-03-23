use Test::More;
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use_ok Mojolicious::Plugin::GSSAPI;

done_testing();
