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
    properties => {
        foo => 'bar',
        bar => 'baz',
    },
);
isa_ok $presto, 'Net::Presto';

my $rows = $presto->select_all('SELECT * FROM catalog');
ok $rows, 'select_all';
my ($jmx) = grep { $_->{catalog_name} eq 'jmx' } @$rows;
ok $jmx, 'has jmx catalog';

my $row = $presto->select_row("SELECT * FROM catalog WHERE catalog_name = 'jmx'");
ok $row, 'select_row';
is $row->{catalog_name}, 'jmx';

my $count = $presto->select_one("SELECT COUNT(1) FROM catalog WHERE catalog_name = 'jmx'");
is $count, 1, 'select_one';

my $sessions = $presto->select_all('SHOW SESSION');
is scalar @$sessions, 2, 'properties';
is_deeply [sort { $a->{Name} cmp $b->{Name} } @$sessions], [
    { Name => 'bar', Value => 'baz' },
    { Name => 'foo', Value => 'bar' },
];

done_testing;
