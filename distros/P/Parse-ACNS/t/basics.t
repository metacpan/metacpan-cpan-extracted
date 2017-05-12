use strict;
use warnings;

use Test::More tests => 19;

use_ok('Parse::ACNS');

foreach my $v (qw(compat 0.6 0.7 1.0 1.1 1.2)) {
    note "testing $v";
    my $p = Parse::ACNS->new( version => $v );
    ok($p, 'created a new parser instance');
    isa_ok($p, 'Parse::ACNS');

    my $reader = $p->reader($v, 'Infringement');
    ok $reader;
}

