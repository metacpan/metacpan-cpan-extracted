use strict;
use Test::More tests => 7;

use Net::RRP::Lite::Response;

my $data = join("\r\n",
		(
		    "200 Command completed successfully",
		    "NameServer:ns2.registrarA.com",
		    "nameserver:ns3.registrarA.com",
		    "registration expiration date:2010-09-22 10:27:00.0",
		    "registrar:registrarA",
		    "registrar transfer date:1999-09-22 10:27:00.0",
		    "status:ACTIVE",
		    "created date:1998-09-22 10:27:00.0",
		    "created by:registrarA",
		    "updated date:2002-09-22 10:27:00.0",
		    "updated by:registrarA",
		)
);
my $res = Net::RRP::Lite::Response->new($data);
is($res->code, 200);
like($res->message, qr/successfully/);
is($res->param('status'), 'ACTIVE');
is($res->param('StaTus'), 'ACTIVE');

my @ns = $res->param('nameserver');
ok(eq_array(\@ns, [qw(ns2.registrarA.com ns3.registrarA.com)]));
is($res->param('updated_by'), 'registrarA');
is($res->param('updated by'), 'registrarA');
