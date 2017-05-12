use strict;
use warnings;
use Test::More skip_all => 'third party tests';
use Test::Deep;

use Net::Amazon::DynamoDB::Table;

my $item;
my $table = Net::Amazon::DynamoDB::Table->new(
    region      => 'us-west-1',
    table       => 'test',
    hash_key    => 'super',
    access_key  => $ENV{AWS_ACCESS_KEY},
    secret_key  => $ENV{AWS_SECRET_KEY},
);

$table->put(Item => { super => 'duper' });
$item = $table->get(super => 'duper');
cmp_deeply $item, { super => 'duper' }, 'put() and get() duper';

$table->put(Item => {super => 'pooper' });
$item = $table->get(super => 'pooper');
cmp_deeply $item, { super => 'pooper' }, 'put() and get() pooper';

my $items_arrayref = $table->scan();
cmp_deeply 
    $items_arrayref,
    [ { super => "duper" }, { super => "pooper" } ],
    'scan()';

my $items_hashref = $table->scan_as_hashref();
cmp_deeply
    $items_hashref,
    { duper => {}, pooper => {} },
    'scan_as_hashref()';

$table->delete(super => 'pooper');
$table->delete(super => 'duper');
$item = $table->get(super => 'duper');
ok !defined $item, 'delete() duper';

done_testing;
