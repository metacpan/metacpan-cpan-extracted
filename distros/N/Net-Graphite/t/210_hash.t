use strict;
use warnings;

use Test::More tests => 2;

use Net::Graphite;
$Net::Graphite::TEST = 1;

{
    my $graphite = Net::Graphite->new(path => 'who.what');

    my $hash = {
        1377872333 => {
            a => { one   => 1, two  => 2 },
            b => { three => 3, four => 4 },
        },
        1377872334 => {
            a => { one   => 1, two  => 2 },
            c => { five  => 5, six  => 6 },
        },
    };

    my $sent = $graphite->send(data => $hash);    # default hash transformer

    my $expected = <<'TXT';
who.what.a.one 1 1377872333
who.what.a.two 2 1377872333
who.what.b.four 4 1377872333
who.what.b.three 3 1377872333
who.what.a.one 1 1377872334
who.what.a.two 2 1377872334
who.what.c.five 5 1377872334
who.what.c.six 6 1377872334
TXT

    is($sent, $expected, 'sent hash');

    my $graphite_no_path = Net::Graphite->new();
    my $sent_with_path = $graphite_no_path->send( path => 'who.what', data => $hash );

    is($sent_with_path, $expected, 'sent hash without hardcoded root path');
}
