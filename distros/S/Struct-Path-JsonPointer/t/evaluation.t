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
    "/0/00"     => bless({E => qr/^Unsigned int without leading zeros allowed only, step #1/}, 'EXCEPTION'),
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

done_testing();
