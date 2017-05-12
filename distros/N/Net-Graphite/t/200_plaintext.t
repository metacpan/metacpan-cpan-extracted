use strict;
use warnings;

use Test::More tests => 1;

use Net::Graphite;
$Net::Graphite::TEST = 1;

{
    my $graphite = Net::Graphite->new();

    my $plaintext = <<'TXT';
base.path.a 1 1377861711
base.path.b 2 1377861711
base.path.c 3 1377861711
base.path.d 4 1377861711
base.path.e 5 1377861711
TXT
    my $sent = $graphite->send(data => $plaintext);

    # fairly useless test..
    is($sent, $plaintext, 'sent plaintext');
}
