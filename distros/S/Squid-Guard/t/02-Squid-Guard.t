# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Squid-Guard.t'

#########################

# Preliminary stuff
use strict;
use File::Temp qw(tempdir);
my $tempdir = tempdir( CLEANUP => 1 ) || die "Cannot create temp dir";
use File::Copy;
copy("t/domains","$tempdir") or die "Copy failed: $!";
copy("t/urls","$tempdir") or die "Copy failed: $!";
copy("t/expressions","$tempdir") or die "Copy failed: $!";
copy("t/userdomains","$tempdir") or die "Copy failed: $!";
copy("t/squid.conf","$tempdir") or die "Copy failed: $!";

use Test::More tests => 29;
BEGIN { use_ok('Squid::Guard') };

# Sanity checks
ok(Squid::Guard->can('new'), 'can new()');
my $lg = Squid::Guard->new( dbdir => $tempdir );
ok( defined $lg );			# check that we got something
#ok( $lg->isa('Squid::Guard') );	# and it's the right class
isa_ok($lg,'Squid::Guard');
ok($lg->can('run'), 'can run()');

# .db file handling
my %categ = ( 'blacklist' => '/' );
$lg->mkdb(%categ);
$lg->addcateg(%categ);
ok( -f "$tempdir/domains.db", 'generated .db domains file' );
ok( -f "$tempdir/urls.db", 'generated .db urls file' );

$lg->readsquidcfg("$tempdir/squid.conf");


sub check($$) {
        my ( $lg, $req ) = @_;
        return 0 if $lg->checkinacl( $req, 'localhost');
        return 'updates' if $lg->checkinacl( $req, 'updates');	# in the real world, one would return 0 for updates, but here we want to check that the acl is evaluated properly
        return 'vpn' if $lg->checkinacl( $req, 'vpn');
        return '88net' if $req->checksrcinnet( '192.168.88.90', '192.168.88.88/29');
        return 'blacklist' if $lg->checkincateg( $req, 'blacklist');
        return 'in-addr' if $lg->checkinaddr($req);
        0;
}

$lg->redir("http://proxy/cgi-bin/denymessage?clientaddr=%a&clientname=%n&clientident=%i&url=%u&block=%t&path=%p");
$lg->checkf(\&check);
#$lg->debug(1);

like($lg->handle( "http://www.youporn.com/ 172.31.30.132/- user2 GET -" ), qr/denymessage.*blacklist/, 'blacklist domains #1');
is($lg->handle(   "http://www.youZorn.com/ 172.31.30.132/- user2 GET -" ), '', 'blacklist domains #2');
like($lg->handle( "http://www.dotted.it/ 172.31.30.132/- user2 GET -" ), qr/denymessage.*blacklist/, 'blacklist domains #3');
like($lg->handle( "http://looki.de/user/pippo 172.31.30.132/- user2 GET -" ), qr/denymessage.*blacklist/, 'blacklist urls #1');
like($lg->handle( "http://tvithai.com/boondee/pippo 172.31.30.132/- user2 GET -" ), qr/denymessage.*blacklist/, 'blacklist urls #2');
like($lg->handle( "http://172.16.5.100/foo 172.31.30.132/- user2 GET -" ), qr/denymessage.*blacklist/, 'blacklist expressions #1');
like($lg->handle( "http://www.foodom.com/ 172.31.30.132/- foouser GET -" ), qr/denymessage.*blacklist/, 'blacklist userdomains #1');
like($lg->handle( "http://www.bardom.com/ 172.31.30.132/- baruser GET -" ), qr/denymessage.*blacklist/, 'blacklist userdomains #2');
is($lg->handle(   "http://www.foodom.com/ 172.31.30.132/- baruser GET -" ), '', 'blacklist userdomains #3');
is($lg->handle(   "http://www.foodom.com/ 172.31.30.132/- nonexistinguser GET -" ), '', 'blacklist userdomains #4');
is($lg->handle(   "http://www.foodom.com/ 172.31.30.132/- - GET -" ), '', 'blacklist userdomains #5');
is($lg->handle(   "http://www.nonexistingdom.com/ 172.31.30.132/- foouser GET -" ), '', 'blacklist userdomains #6');
# TODO: perform these tests only if the system has a bin group with the root user in it
#is($lg->handle(   "http://www.foodom.com/ 172.31.30.132/- root GET -" ), '', 'blacklist userdomains for unix group #1');
#like($lg->handle(   "http://www.bindom.com/ 172.31.30.132/- root GET -" ), qr/denymessage.*blacklist/, 'blacklist userdomains for unix group #2');

like($lg->handle( "www.youporn.com:443 172.31.30.132/- user2 CONNECT -" ), qr/denymessage.*blacklist/, 'blacklist connect method #1');
is($lg->handle(   "www.youZorn.com:443 172.31.30.132/- user2 CONNECT -" ), '', 'blacklist connect method #2');

is($lg->handle(   "www.youporn.com:443 127.0.0.1/- user2 CONNECT -" ), '', 'acl test #1');
like($lg->handle(   "www.youporn.com:443 127.0.0.2/- user2 CONNECT -" ), qr/denymessage.*blacklist/, 'acl test #2');
like($lg->handle(   "http://www.windowsupdate.com/ 172.31.30.132/- user2 GET -" ), qr/denymessage.*updates/, 'acl test #3');
like($lg->handle(   "www.windowsupdate.com:443 172.31.30.132/- user2 CONNECT -" ), qr/denymessage.*updates/, 'acl test #4');
like($lg->handle(   "http://www.foodom.com/ 192.168.34.2/- user2 CONNECT -" ), qr/denymessage.*vpn/, 'acl test #5');
is($lg->handle(   "http://www.foodom.com/ 192.168.35.2/- user2 CONNECT -" ), '', 'acl test #6');
like($lg->handle(   "http://www.foodom.com/ 192.168.88.90/- user2 CONNECT -" ), qr/denymessage.*88net/, 'acl test #7');
is($lg->handle(   "http://www.foodom.com/ 192.168.89.99/- user2 CONNECT -" ), '', 'acl test #8');

