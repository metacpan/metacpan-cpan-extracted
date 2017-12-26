#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path path2str);
use Test::More tests => 16;

use lib 't';
use _common qw(roundtrip);

### EXCEPTIONS ###

eval { str2path(undef) };
like($@, qr/^Undefined path passed/);

eval { str2path({}) };
like($@, qr/^Failed to parse passed path 'HASH\(/);

eval { str2path('{a},{b}') };
like($@, qr/^Unsupported thing ',' in the path, step #1 /, "garbage between path elements");

eval { str2path('{a} []') };
like($@, qr/^Unsupported thing ' ' in the path, step #1 /, "space between path elements");

eval { str2path('{a};[]') };
like($@, qr/^Unsupported thing ';' in the path, step #1 /, "semicolon between path elements");

eval { str2path('[0}') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unmatched brackets");

eval { str2path('{a') };
like($@, qr/^Unsupported thing '\{a' in the path, step #0 /, "unclosed curly brackets");

eval { str2path('[0') };
like($@, qr/^Unsupported thing '\[0' in the path, step #0 /, "unclosed square brackets");

eval { str2path('(0)') };
like($@, qr/^Unsupported thing '0' as hook, step #0 /, "parenthesis in the path");

eval { str2path('{a}{b+c}') };
like($@, qr/^Unsupported thing '\+' for hash key, step #1 /, "garbage in hash keys definition");

eval { str2path('{/a//}') };
like($@, qr|^Unsupported thing '/' for hash key, step #0 |, "regexp and one more slash");

eval { path2str(undef) };
like($@, qr/^Arrayref expected for path/, "undef as path");

eval { path2str([{},"garbage"]) };
like($@, qr/^Unsupported thing in the path, step #1 /, "trash as path step");

### Immutable $_ ###

$_ = 'bareword';
eval { str2path($_) };
like($@, qr/^Unsupported thing 'bareword' in the path, step #0 at /);
is($_, 'bareword', '$_ must remain unchanged');

roundtrip ([], '', 'Empty path');
