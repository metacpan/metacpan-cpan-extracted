use strict;
use Importer 'NewsExtractor::TextUtil' => 'normalize_whitespace';

use Test2::V0;

my ($s1, $s2);
$s1 = 'Where am I ?';
$s2 = normalize_whitespace($s1);
is $s2, $s1;

$s1 = ' Where  am  I ?  ';
$s2 = normalize_whitespace($s1);
isnt $s2, $s1;
is $s2, 'Where am I ?';

done_testing;
