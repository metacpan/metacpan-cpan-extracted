use strict;
use warnings;

use Test::More 'no_plan';
use Parse::Win32Registry 0.60 qw(
    REG_NONE
    REG_SZ
    REG_EXPAND_SZ
    REG_BINARY
    REG_DWORD
    REG_DWORD_BIG_ENDIAN
    REG_LINK
    REG_MULTI_SZ
    REG_RESOURCE_LIST
    REG_FULL_RESOURCE_DESCRIPTOR
    REG_RESOURCE_REQUIREMENTS_LIST
    REG_QWORD
);

{
    my @tests = (
        ['REG_NONE' => 0],
        ['REG_SZ' => 1],
        ['REG_EXPAND_SZ' => 2],
        ['REG_BINARY' => 3],
        ['REG_DWORD' => 4],
        ['REG_DWORD_BIG_ENDIAN' => 5],
        ['REG_LINK' => 6],
        ['REG_MULTI_SZ' => 7],
        ['REG_RESOURCE_LIST' => 8],
        ['REG_FULL_RESOURCE_DESCRIPTOR' => 9],
        ['REG_RESOURCE_REQUIREMENTS_LIST' => 10],
        ['REG_QWORD' => 11],
    );

    foreach my $test (@tests) {
        my ($name, $constant) = @{ $test };
        cmp_ok(eval $name, '==', $constant, $name);
    }
}
