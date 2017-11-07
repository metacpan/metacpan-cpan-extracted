#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(ps_parse ps_serialize);
use Test::More tests => 16;

use lib 't';
use _common qw(roundtrip);

### EXCEPTIONS ###

eval { ps_parse(undef) };
like($@, qr/^Undefined path passed/);

eval { ps_parse({}) };
like($@, qr/^Failed to parse passed path 'HASH\(/);

eval { ps_parse('{a},{b}') };
like($@, qr/^Unsupported thing ',' in the path, step #1 /, "garbage between path elements");

eval { ps_parse('{a} []') };
like($@, qr/^Unsupported thing ' ' in the path, step #1 /, "space between path elements");

eval { ps_parse('{a};[]') };
like($@, qr/^Unsupported thing ';' in the path, step #1 /, "semicolon between path elements");

eval { ps_parse('[0}') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unmatched brackets");

eval { ps_parse('{a') };
like($@, qr/^Unsupported thing '\{a' in the path, step #0 /, "unclosed curly brackets");

eval { ps_parse('[0') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unclosed square brackets");

eval { ps_parse('(0)') };
like($@, qr/^Unsupported thing '0' as hook, step #0 /, "parenthesis in the path");

eval { ps_parse('{a}{b+c}') };
like($@, qr/^Unsupported thing '\+' for hash key, step #1 /, "garbage in hash keys definition");

eval { ps_parse('{/a//}') };
like($@, qr|^Unsupported thing '/' for hash key, step #0 |, "regexp and one more slash");

eval { ps_serialize(undef) };
like($@, qr/^Arrayref expected for path/, "undef as path");

eval { ps_serialize([{},"garbage"]) };
like($@, qr/^Unsupported thing in the path, step #1 /, "trash as path step");

### Immutable $_ ###

$_ = 'bareword';
eval { ps_parse($_) };
like($@, qr/^Unsupported thing 'bareword' in the path, step #0 at /);
is($_, 'bareword', '$_ must remain unchanged');

roundtrip ([], '', 'Empty path');
