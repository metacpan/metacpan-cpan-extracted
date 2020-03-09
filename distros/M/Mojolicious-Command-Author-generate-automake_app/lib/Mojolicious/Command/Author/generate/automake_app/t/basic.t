use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('<%= ${class} %>');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
