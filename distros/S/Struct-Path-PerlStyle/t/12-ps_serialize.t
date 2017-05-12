#!perl -T

use strict;
use warnings;
use Test::More tests => 31;
use Storable qw(freeze);

$Storable::canonical = 1;

use Struct::Path::PerlStyle qw(ps_serialize);

my $str;

eval { $str = ps_serialize(undef) };
like($@, qr/^Path must be an arrayref/, "undef as path");

$str = ps_serialize([]);
is($str, '', "empty path");

eval { $str = ps_serialize([{},"garbage"]) };
like($@, qr/^Unsupported thing in the path \(step #1\)/, "trash as path step");

# trash in hash definition #1
eval { $str = ps_serialize([{garbage => ['a']}]) };
like($@, qr/^Unsupported hash definition \(step #0\)/);

# trash in hash definition #2
eval { $str = ps_serialize([{keys => 'a'}]) };
like($@, qr/^Unsupported hash definition \(step #0\)/);

# trash in hash definition #3
eval { $str = ps_serialize([{keys => ['a'], garbage => ['b']}]) };
like($@, qr/^Unsupported hash definition \(step #0\)/);

# trash in hash definition #4
eval { $str = ps_serialize([{keys => [undef]}]) };
like($@, qr/Unsupported hash key type 'undef' \(step #0\)/);

# trash in hash definition #5
eval { $str = ps_serialize([{keys => ['test',[]]}]) };
like($@, qr/^Unsupported hash key type 'ARRAY' \(step #0\)/);

### HASHES ###

$str = ps_serialize([{keys => ['a']},{},{keys => ['c']}]);
is($str, '{a}{}{c}', "empty hash path");

$str = ps_serialize([{keys => [""]},{keys => [" "]}]);
is($str, '{""}{" "}', "Empty string and space as hash keys");

$str = ps_serialize([{keys => ['a']},{keys => ['b']},{keys => ['c']}]);
is($str, '{a}{b}{c}', "simple hash path");

$str = ps_serialize([{keys => ['b','a']},{keys => ['c','d']}]);
is($str, '{b,a}{c,d}', "order specified hash path");

$str = ps_serialize([{keys => [0,2,100]},{keys => [5_000,4_000]}]);
is($str, "{0,2,100}{5000,4000}", "Numbers as hash keys");

my $path = [{keys => ['three   spaces']},{keys => ['two  spases']},{keys => ['one ']},{keys => ['none']}];
my $frozen = freeze($path);
$str = ps_serialize($path);
is($str, '{"three   spaces"}{"two  spases"}{"one "}{none}', "Quotes for spaces");
is($frozen, freeze($path), "must remain unchanged");

$str = ps_serialize([{keys => ['three			tabs']},{keys => ['two		tabs']},{keys => ['one	']},{keys => ['none']}]);
is($str, '{"three\t\t\ttabs"}{"two\t\ttabs"}{"one\t"}{none}', "Quotes and escapes for tabs");

$str = ps_serialize([{keys => ['delimited:by:colons','some:more']},]);
is($str, '{"delimited:by:colons","some:more"}', "Quotes for colons");

$str = ps_serialize([{keys => ['/looks like regexp, but string/','/another/']},]);
is($str, '{"/looks like regexp, but string/","/another/"}', "Quotes for regexp looking strings");

$str = ps_serialize([{keys => ['"','""', "'", "''", "\n", "\t"]}]);
is($str, '{"\"","\"\"","\'","\'\'","\n","\t"}', "Escaping");

$str = ps_serialize([{keys => ['кириллица']}]);
is($str, '{"кириллица"}', "non ASCII characters must be quoted even it's a bareword");

$str = ps_serialize([{keys => [42, '43', '42.0', 42.1, -41, -41.3, '-42.3', '1e+3', 1e3, 1e-25]}]);
is($str, '{42,43,42.0,42.1,-41,-41.3,-42.3,1e+3,1000,1e-25}', "numbers must remain unquoted");

### ARRAYS ###

eval { $str = ps_serialize([["a"]]) };
like($@, qr/^Incorrect array index 'a' \(step #0\)/, "garbage: non-number as index");

eval { $str = ps_serialize([[0.3]]) };
like($@, qr/^Incorrect array index '0.3' \(step #0\)/, "garbage: float as index");

$str = ps_serialize([[2],[5],[0]]);
is($str, '[2][5][0]', "explicit array path");

$str = ps_serialize([[2],[],[0]]);
is($str, '[2][][0]', "implicit array path");

$str = ps_serialize([[-2],[-5],[0]]);
is($str, '[-2][-5][0]', "negative indexes");

$str = ps_serialize([[0,2],[7,5,2]]);
is($str, '[0,2][7,5,2]', "array path with slices");

$str = ps_serialize([[0,1,2],[6,7,8,10]]);
is($str, '[0..2][6..8,10]', "ascending ranges");

$str = ps_serialize([[2,1,0],[10,8,7,6]]);
is($str, '[2..0][10,8..6]', "descending ranges");

$str = ps_serialize([[-2,-1,0,1,2,1,0,-1,-2]]);
is($str, '[-2..2,1..-2]', "bidirectional ranges (asc-desc)");

$str = ps_serialize([[3,2,1,2,3]]);
is($str, '[3..1,2..3]', "bidirectional ranges (desc-asc)");
