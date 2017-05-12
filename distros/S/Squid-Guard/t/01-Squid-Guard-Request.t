# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Squid-Guard.t'

#########################

# Preliminary stuff
use strict;

use Test::More tests => 58;
BEGIN { use_ok('Squid::Guard::Request') };

# Sanity checks
ok(Squid::Guard::Request->can('new'), 'can new()');
my $req = Squid::Guard::Request->new( 'http://www.iotti.biz/ 172.31.30.132/- user1 GET -' );
ok( defined $req );			# check that we got something
isa_ok($req,'Squid::Guard::Request');
is($req->url,		'http://www.iotti.biz/','request #5');
is($req->addr,		'172.31.30.132',	'request #6');
is($req->ident,		'user1',		'request #7');
is($req->method,	'GET',			'request #8');
is($req->scheme,	'http',			'request #9');
is($req->authority,	'www.iotti.biz',	'request #10');
is($req->host,		'www.iotti.biz',	'request #11');
is($req->_port,		undef,			'request #12');
is($req->port,		'80',			'request #13');
is($req->path,		'/',			'request #14');

$req = Squid::Guard::Request->new( 'http://www.iotti.biz/dir/file.pl?pippo=uno 172.31.30.132/- user1 GET -' );
ok( defined $req );			# check that we got something
is($req->url,		'http://www.iotti.biz/dir/file.pl?pippo=uno','request #16');
is($req->addr,		'172.31.30.132',	'request #17');
is($req->ident,		'user1',		'request #18');
is($req->method,	'GET',			'request #19');
is($req->scheme,	'http',			'request #20');
is($req->authority,	'www.iotti.biz',	'request #21');
is($req->host,		'www.iotti.biz',	'request #22');
is($req->_port,		undef,			'request #23');
is($req->port,		'80',			'request #24');
is($req->path,		'/dir/file.pl',		'request #25');
is($req->query,		'pippo=uno',		'request #26');
is($req->path_query,	'/dir/file.pl?pippo=uno','request #27');
is($req->authority_path_query,	'www.iotti.biz/dir/file.pl?pippo=uno','request #28');

$req = Squid::Guard::Request->new( 'http://www.iotti.biz:551/dir/file.pl 172.31.30.132/- user1 GET -' );
ok( defined $req );			# check that we got something
is($req->url,		'http://www.iotti.biz:551/dir/file.pl','request #29');
is($req->addr,		'172.31.30.132',	'request #31');
is($req->ident,		'user1',		'request #32');
is($req->method,	'GET',			'request #33');
is($req->scheme,	'http',			'request #34');
is($req->authority,	'www.iotti.biz:551',	'request #35');
is($req->host,		'www.iotti.biz',	'request #36');
is($req->_port,		551,			'request #37');
is($req->port,		551,			'request #38');
is($req->path,		'/dir/file.pl',		'request #39');
is($req->path_query,	'/dir/file.pl',		'request #40');
is($req->authority_path_query,	'www.iotti.biz:551/dir/file.pl',	'request #41');
is($req->kvpairs,	undef,			'request #42');

$req = Squid::Guard::Request->new( 'www.iotti.biz:443 172.31.30.132/- user1 CONNECT myip=172.16.0.38 myport=8080' );
ok( defined $req );			# check that we got something
is($req->url,		'www.iotti.biz:443',	'request #44');
is($req->addr,		'172.31.30.132',	'request #45');
is($req->ident,		'user1',		'request #46');
is($req->method,	'CONNECT',		'request #47');
is($req->_scheme,	undef,			'request #48');
is($req->scheme,	'https',		'request #49');
is($req->authority,	'www.iotti.biz:443',	'request #50');
is($req->host,		'www.iotti.biz',	'request #51');
is($req->_port,		443,			'request #52');
is($req->port,		443,			'request #53');
is($req->path_query,	'',			'request #54');
is($req->authority_path_query,	'www.iotti.biz:443',	'request #55');
is($req->_kvpairs,	'myip=172.16.0.38 myport=8080',	'request #56');
is($req->kvpairs('myip'),	'172.16.0.38',	'request #57');
is($req->kvpairs('myport'),	'8080',		'request #58');


