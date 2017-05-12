use strict;
use warnings;
use lib 't';

use Mojolicious::Lite;
use Test::More tests => 16;
use Test::Mojo;

use TestHelper;

sub ie_request
{
    my $url = shift;
    my $t = Test::Mojo->new;
    $t->get_ok($url)
      ->status_is(401);

    my $headers = build_auth_request($t->tx, @_);
    $headers->{'User-Agent'} = IE6;
    $t->get_ok($url, $headers)      
}

sub bad_uri { ie_request(shift, uri => shift) }
sub no_opaque { ie_request(shift, opaque => '') }

my $uri = '/dont_support_broken_browsers';
my $req = "$uri?x=y";
get $uri => create_action(support_broken_browsers => 0);
bad_uri($req, $uri)->status_is(400);
no_opaque($req)->status_is(400);

$uri = '/support_broken_browsers';
$req = "$uri?x=y";
get $uri => create_action(support_broken_browsers => 1);
bad_uri($req, $uri)->status_is(200);
no_opaque($req)->status_is(200);

