#!/usr/bin/perl
# Every handle the ABI forward-declares must be declared the same way inside.
#
# sa_abi.h says `typedef struct sa_hash sa_hash;` under an SA_HASH_FWD guard,
# so a consumer can hold the pointer without the struct. The provider build
# includes that header AFTER the private one that defines the struct, and if
# the private header spelled it `typedef struct sa_hash { ... } sa_hash;`, the
# ABI header's line is a SECOND typedef of the same name. C11 allows that; C89
# does not, and gcc 4.2.1 on the FreeBSD 9 smoker refused 0.03 with
# "redefinition of typedef 'sa_hash'" for four tenants, on every perl it had.
# Nothing here noticed, because every compiler in reach is C11.
#
# So: for each name the ABI forward-declares, the private header must carry
# the same guard and close its struct with `};`, never `} name;`.

use strict;
use warnings;
use Test::More;

open my $abi, '<', 'include/sa_abi.h' or plan skip_all => 'run from the distribution root';
my @names;
while (<$abi>) { push @names, $1 if /^typedef struct (sa_\w+) \1;/ }
close $abi;
plan skip_all => 'no forward typedefs found' unless @names;

my %src;
for my $f (glob 'include/sa/*.h') {
    open my $fh, '<', $f or die "$f: $!";
    local $/;
    $src{$f} = <$fh>;
}

for my $name (@names) {
    my ($guard) = map { uc } $name =~ /^sa_(\w+)$/;
    my @closes = grep { $src{$_} =~ /^\} \Q$name\E;/m } sort keys %src;
    is("@closes", '', "$name is never closed as `} $name;` inside a private header")
        or diag("declare it as the ABI does: #ifndef SA_${guard}_FWD / typedef struct $name $name; "
              . "/ #endif, then `struct $name { ... };`");
}

done_testing;
