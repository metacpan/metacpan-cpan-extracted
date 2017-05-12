use Test::More;
use Test::Fatal;

use strict;
use warnings;

use_ok('Net::LDNS');

my $p = new_ok('Net::LDNS::Packet' => ['www.example.org', 'SOA', 'IN']);

foreach my $r (qw[NOERROR FORMERR SERVFAIL NXDOMAIN NOTIMPL REFUSED YXDOMAIN YXRRSET NXRRSET NOTAUTH NOTZONE]) {
    is($p->rcode($r), $r, $r);
}
like( exception {$p->rcode('gurksallad')}, qr/Unknown RCODE: gurksallad/, 'Expected exception' );

foreach my $r (qw[QUERY IQUERY STATUS NOTIFY UPDATE]) {
    is($p->opcode($r), $r, $r);
}
like( exception {$p->opcode('gurksallad')}, qr/Unknown OPCODE: gurksallad/, 'Expected exception' );

is($p->id(4711), 4711, 'Setting ID');
is($p->id(2147488359), 4711, 'Wraparound ID');

is($p->querytime(4711), 4711, 'Setting query time');
is($p->querytime(2147488359), 2147488359, 'Setting larger query time');

is($p->answerfrom, undef, 'No answerfrom');
$p->answerfrom('127.0.0.1');
is($p->answerfrom, '127.0.0.1', 'Localhost');


done_testing();