#!perl -T

use strict;
use warnings;

use Struct::Path qw(path);
use Struct::Path::JsonPointer qw(str2path);
use Test::More;

use lib 't';
use _common qw(t_dump);

my $data = {
    "foo"   => ["bar", "baz"],
    ""      => 0,
    "a/b"   => 1,
    "c%d"   => 2,
    "e^f"   => 3,
    "g|h"   => 4,
    "i\\j"  => 5,
    "k\"l"  => 6,
    " "     => 7,
    "m~n"   => 8
};

my @tests = (
    ""          => $data,
    "/foo"      => ["bar", "baz"],
    "/foo/0"    => "bar",
    "/"         => 0,
    "/a~1b"     => 1,
    "/c%d"      => 2,
    "/e^f"      => 3,
    "/g|h"      => 4,
    "/i\\j"     => 5,
    "/k\"l"     => 6,
    "/ "        => 7,
    "/m~0n"     => 8,
);

while (@tests) {
    my ($path, $value) = splice @tests, 0, 2;
    my ($found) = path($data, str2path($path), deref => 1);

    is_deeply($found, $value, "<<< $path >>>") ||
        diag t_dump $found;
}

$data = {
    "0"     => [0, 1],
    "-"     => {k => 'v'},
};

@tests = (
    "/0/1"      => 1,
    "/0/2"      => bless({E => qr/^Index is out of range, step #1 /}, 'EXCEPTION'),
    "/0/00"     => bless({E => qr/^Incorrect array index, step #1 /}, 'EXCEPTION'),
    "/0/1/-"    => bless({E => qr/^Structure doesn't match, step #2 /}, 'EXCEPTION'),
    "/0/-"      => undef, # should be new array item
    "/-"        => {k => 'v'},
    "/-/-"      => bless({E => qr/^'-' key doesn't exist, step #1 /}, 'EXCEPTION'),
);

while (@tests) {
    my ($path, $value) = splice @tests, 0, 2;
    my ($found) = eval { path($data, str2path($path), deref => 1) };

    if (ref $value eq 'EXCEPTION') {
        like($@, $value->{E});
    } else {
        is_deeply($found, $value, "<<< $path >>>") ||
            diag t_dump $found;
    }
}

is_deeply(
    $data->{'0'},
    [0, 1, undef],
    "Hyphen as array index should append new undef item to array"
);

# delete tests
$data = [0,1,2];
eval { path($data, str2path('/2'), delete => 1) };
is_deeply($data, [0,1], 'Last item should be removed');

# expand tests
eval { path([0,1,2], str2path('/3'), expand => 1) };
is($@, '', 'last idx + 1 is allowed to expand');

eval { path([0,1,2], str2path('/4'), expand => 1) };
like($@, qr/Index is out of range, step #0 /, 'last idx + 2 and more is not allowed to expand');

eval { path({}, str2path('/2'), expand => 1) };
is($@, '');

eval { path({}, str2path('/2'), expand => 0) };
like($@, qr/'2' key doesn't exist, step #0 /);

# insert tests
$data = [0,1,2];
eval { path($data, str2path('/2'), assign => 'new value') };
is_deeply($data, [0,1,'new value'], 'Replace array item');

$data = [0,1,2];
eval { path($data, str2path('/2'), assign => 'new value', insert => 1) };
is_deeply($data, [0,1,'new value',2], 'Insert array item');

done_testing();
