use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use ok 'TestApp';
use Catalyst::Test 'TestApp';
use Test::WWW::Mechanize::Catalyst 'TestApp';
use HTTP::Request::Common qw(GET POST);


my $mech = Test::WWW::Mechanize::Catalyst->new();

# not logged in so should essentially have no menu.
my ($res, $c) = ctx_request('/');
my $menu = $c->menu_data;
is scalar @$menu, 0, 'Should have no apps.';


($res, $c) = ctx_request(POST ('/login', [ username => 'appkitadmin', password => 'password'] ));
ok $res, 'Check response';
$menu = $c->menu_data;
is scalar @$menu, 1, 'Should have 1 apps.';
# FIXME: now probe menu info.

done_testing;
