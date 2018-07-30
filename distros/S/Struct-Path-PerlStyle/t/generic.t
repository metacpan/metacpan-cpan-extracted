#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path path2str);
use Test::More tests => 14;

use lib 't';
use _common qw(roundtrip);

### EXCEPTIONS ###

eval { str2path(undef) };
like($@, qr/^Undefined path passed/);

eval { str2path({}) };
like($@, qr/^Unsupported thing in the path, step #0: 'HASH\(0x/);

eval { str2path('{a},{b}') };
like($@, qr/^Unsupported thing in the path, step #1: ',\{b\}' /, "garbage between path elements");

eval { str2path('{a} []') };
like($@, qr/^Unsupported thing in the path, step #1: ' \[\]'/, "space between path elements");

eval { str2path('{a};[]') };
like($@, qr/^Unsupported thing in the path, step #1: ';\[\]' /, "semicolon between path elements");

eval { str2path('[0}') };
like($@, qr/^Unsupported thing in the path, step #0: '\[0\}' /, "unmatched brackets");

eval { str2path('{a') };
like($@, qr/^Unsupported thing in the path, step #0: '\{a' /, "unclosed curly brackets");

eval { str2path('[0') };
like($@, qr/^Unsupported thing in the path, step #0: '\[0' /, "unclosed square brackets");

eval { str2path('(0') };
like($@, qr/^Unsupported thing in the path, step #0: '\(0' /, "unclosed parenthesis");

eval { path2str(undef) };
like($@, qr/^Arrayref expected for path/, "undef as path");

eval { path2str([{},"garbage"]) };
like($@, qr/^Unsupported thing in the path, step /, "trash as path step");

### Immutable $_ ###

$_ = 'bareword';
eval { str2path($_) };
like($@, qr/^Unsupported thing in the path, step #0: 'bareword' /);
is($_, 'bareword', '$_ must remain unchanged');

roundtrip ([], '', 'Empty path');
