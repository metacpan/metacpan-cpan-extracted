use strict;
use Test::More;

use PICA::Data ':all';

use PICA::Parser::Plain;
my $record = PICA::Parser::Plain->new('./t/files/pica.plain')->next;

foreach ('019@', pica_path('019@')) {
    is_deeply [pica_values($record, $_)], ['XB-CN'], 'pica_values';
}

bless $record, 'PICA::Data';
my %map = (
    '019@/0-1' => ['XB'],
    '019@/1'   => ['B'],
    '019@/5'   => [],
    '019@/3-'  => ['CN'],
    '019@/-1'  => ['XB'],
    '019@x'    => [],
    '1...b'    => ['9330', 'test$'],
    '?+#'      => [],
);
foreach (keys %map) {
    is_deeply [$record->values($_)], $map{$_}, "->values($_)";
}

is_deeply [$record->value('1...b')], ['9330'], '->value';
is_deeply [$record->value('234X')], [], '->value (empty)';

is_deeply $record->fields('010@'), [['010@', '', 'a' => 'chi']], '->fields';
is @{$record->fields}, 18, '->fields';

is_deeply $record->fields('003@', '010@'),
    [['003@', '', '0' => '12345'], ['010@', '', 'a' => 'chi']],
    '->fields(...)';

is $record->id, '12345', '->id';

is_deeply $record->fields('?!*~'), [], 'invalid PICA path';
is scalar @{pica_fields($record, '1...')}, 5, 'pica_fields';

my $field = ['000@', '', '0', '0'];
my $annotated = [@$field, ' '];
is pica_annotation($field), undef, 'no annotation';
is pica_annotation($annotated), ' ', 'get annotation';

pica_annotation($annotated, 'x');
is pica_annotation($annotated), 'x', 'set annotation';
pica_annotation($field, ' ');
pica_annotation($annotated, undef);
is pica_annotation($field), ' ', 'added annotation';
is pica_annotation($annotated), undef, 'removed annotation';

ok pica_empty([]), 'empty';
ok pica_empty({ record => [] }), 'empty';

is $record->subfields('003@')->{0}, '12345', 'subfields';
is_deeply $record->subfields('01..')->mixed, {
    0 => '0',
    a => [qw(chi 2004 XB-CN)],
    n => '2004.01',
    x => '',
    y => ''
  }, 'subfields';

done_testing;
