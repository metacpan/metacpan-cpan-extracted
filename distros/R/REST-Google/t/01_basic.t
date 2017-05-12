#
# $Id$

use strict;

use Test::More tests => 3;

BEGIN { use_ok( "REST::Google" ); }

REST::Google->service('http://ajax.googleapis.com/ajax/services/search/web');
REST::Google->http_referer('http://www.cpan.org');

my $search = REST::Google->new('Jimi Hendrix');

isa_ok( $search, 'REST::Google', "search object" );

ok(defined $search->responseStatus, "search status");
