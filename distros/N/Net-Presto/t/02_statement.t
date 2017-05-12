use strict;
use warnings;

use Test::More;
use Net::Presto;

my $server = $ENV{TEST_PRESTO_SERVER}
        or plan skip_all => '$ENV{TEST_PRESTO_SERVER} required';

my $presto = Net::Presto->new(
    server  => $server,
    user    => __FILE__ . " (Net::Presto/$Net::Presto::VERSION)",
    catalog => 'jmx', # require jmx catalog
    schema  => 'sys',
);

my $st = $presto->execute('SELECT * FROM catalog');
isa_ok $st, 'Net::Presto::Statement';
my @rows;
while (my $rows = $st->fetch) {
    push @rows, @$rows;
}
is(scalar(grep { $_->[0] eq 'jmx' } @rows), 1, 'fetch');

$st = $presto->execute('SELECT * FROM catalog');
@rows = ();
while (my $rows = $st->fetch_hashref) {
    push @rows, @$rows;
}
is(scalar(grep { $_->{catalog_name} eq 'jmx' } @rows), 1, 'fetch_hashref');

$st = $presto->execute('SELECT * FROM catalog');
ok $st->cancel, 'cancel';

done_testing;
