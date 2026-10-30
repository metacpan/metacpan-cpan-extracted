#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPSess;

my $PING = { jsonrpc => '2.0', id => 1, method => 'ping' };
my $t = sess_app('');

my ($sid) = init_session($t);
is((send_msg($t, $PING, sid => $sid))[0], 200, 'a live session');
my ($s, $r) = send_msg($t, undef, sid => $sid, http => 'DELETE');
is($s, 204, 'DELETE ends it with 204');
is($t->body, '', 'and no body');
is((send_msg($t, $PING, sid => $sid))[0], 404, 'a request after it is 404');
is((send_msg($t, undef, sid => $sid, http => 'DELETE'))[0], 404, 'and so is a second DELETE');

($s, $r) = send_msg($t, undef, http => 'DELETE');
is($s, 400, 'DELETE with no session id is 400');
is((send_msg($t, undef, sid => 'B' x 22, http => 'DELETE'))[0], 404, 'an unknown one is 404');

my ($mine) = init_session($t, auth => 'Bearer alice');
is((send_msg($t, undef, sid => $mine, auth => 'Bearer mallory', http => 'DELETE'))[0], 404,
    'another credential cannot end it');
is((send_msg($t, $PING, sid => $mine, auth => 'Bearer alice'))[0], 200, 'so it still works');

is((send_msg($t, undef, sid => $mine, auth => 'Bearer alice', http => 'DELETE',
             env => {}, ))[0], 204, 'its owner can');
($s) = send_msg($t, undef, sid => $sid, http => 'DELETE',
                env => { HTTP_ORIGIN => 'http://evil.test', HTTP_HOST => 'localhost' });
is($s, 403, 'DELETE checks Origin too');

$t = sess_app(q{session => 0}, store => '');
$t->request_ok('DELETE', '/mcp');
is($t->status, 405, 'session => 0: DELETE is 405');
is($t->header('Allow'), 'POST', 'Allow: POST');

done_testing;
