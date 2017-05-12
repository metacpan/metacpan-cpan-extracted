use strict;
use warnings;

use Test::More tests => 11;

use Net::Graphite;
$Net::Graphite::TEST = 1;

{
    my $graphite = Net::Graphite->new();
    is($graphite->{host}, '127.0.0.1', 'default constructor: host default');
    is($graphite->{port}, 2003, 'default constructor: port default');

    my $sent = $graphite->send(
        path => 'foo.bar',
        value => 23,
        time => 1000000000,
    );
    is($sent, "foo.bar 23 1000000000\n", 'default constructor: sent args');
}

{
    my $graphite = Net::Graphite->new(
        host => '127.0.0.2',
        port => 2004,
        path => 'foo.bar.baz',
    );

    is($graphite->{host}, '127.0.0.2', 'named param constructor: host set');
    is($graphite->{port}, 2004, 'named param constructor: port set');
    is($graphite->{path}, 'foo.bar.baz', 'named param constructor: path set');

    my $sent = $graphite->send(6);
    like($sent, qr/^foo\.bar\.baz 6 [0-9]{10}$/, 'named param constructor: sent value');
}

{
    my $graphite = Net::Graphite->new({
        host => '127.0.0.2',
        port => 2004,
        path => 'foo.bar.baz',
    });

    is($graphite->{host}, '127.0.0.2', 'hashref constructor: host set');
    is($graphite->{port}, 2004, 'hashref constructor: port set');
    is($graphite->{path}, 'foo.bar.baz', 'hashref constructor: path set');

    my $sent = $graphite->send(6);
    like($sent, qr/^foo\.bar\.baz 6 [0-9]{10}$/, 'hashref constructor: sent value');
}
