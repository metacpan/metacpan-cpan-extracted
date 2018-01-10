#!perl -T

use strict;
use warnings;

use Struct::Path::JsonPointer qw(str2path path2str);
use Test::More tests => 12;

use lib 't';
use _common qw(roundtrip t_dump);

### EXCEPTIONS ###

eval { path2str(undef) };
like($@, qr/^Arrayref expected for path/, "undef as path");

eval { path2str([{}]) };
like($@, qr/^Only keys allowed for hashes, step #0/, "all hash keys step (no keys)");

eval { path2str([{K => []}]) };
like($@, qr/^Only one hash key allowed, step #0 /, "all hash keys step (no indexes)");

eval { path2str([{K => {}}]) };
like($@, qr/^Incorrect hash keys format, step #0 /, "all hash keys step");

eval { path2str([{R => []}]) };
like($@, qr/^Only keys allowed for hashes, step #0/, "hash regs step");

eval { path2str([[]]) };
like($@, qr/^Only one array index allowed, step #0 /, "all array items step");

eval { path2str([[0],['a']]) };
like($@, qr/^Incorrect array index, step #1 /, "string for array index");

eval { path2str([[0.2]]) };
like($@, qr/^Incorrect array index, step #0 /, "float for array index");

eval { path2str(["garbage"]) };
like($@, qr/^Unsupported thing in the path, step #0 /, "trash as path step");

# only non numeric and non hyphen keys explicitly converts to hash keys
roundtrip(
    [],
    '',
    'empty path (whole struct)'
);

roundtrip(
    [{K => ['aa']},{K => ['bb']},{K => ['cc']}],
    '/aa/bb/cc',
    'regular hash keys'
);

roundtrip(
    [{K => ['~~~']},{K => ['///']},{K => ['~0~1~0']}],
    '/~0~0~0/~1~1~1/~00~01~00',
    'escaped sequences'
);

