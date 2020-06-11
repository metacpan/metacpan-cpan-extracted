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

is_deeply $record->fields('010@'), [['010@', '', 'a' => 'chi']], '->field';

is_deeply $record->fields('003@', '010@'),
    [['003@', '', '0' => '12345'], ['010@', '', 'a' => 'chi']],
    '->field(...)';

is_deeply $record->fields('?!*~'), [], 'invalid PICA path';
is scalar @{pica_fields($record, '1...')}, 5, 'pica_fields';

done_testing;
