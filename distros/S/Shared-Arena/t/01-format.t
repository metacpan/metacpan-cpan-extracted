#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# The layout, asserted from Perl.
#
# These are not decoration. Two processes sharing a named region are not
# necessarily the same build - a 32-bit perl and a 64-bit perl can open the same
# name - so the header records its own dimensions and a process whose compiled
# layout disagrees fails open instead of reading a shape it does not share.
# Which makes every number here a contract, and a silent change to one of them
# a way for two builds to quietly disagree about where the registry is.

my %L = Shared::Arena::_layout();

is($L{magic}, 0x4E524153, 'the magic is "SARN" read as a native word');
is($L{layout}, 2, 'layout version 2 (bumped in 0.03: the map slot grew a ttl)');

# The alignment every carve starts on. Sixteen rather than eight because a
# tenant may want a 16-byte atomic or a vector load, and an arena that hands out
# 8-aligned regions cannot promise either.
is($L{align}, 16, 'regions are carved 16-aligned');
ok($L{align} && ($L{align} & ($L{align} - 1)) == 0,
   'and the alignment is a power of two, which sa_align_up assumes');

# 31 usable bytes plus a NUL. Chosen to fit inside what macOS allows for a
# POSIX shared memory name, which is far shorter than PATH_MAX and is the
# reason a name that works on Linux can fail there.
is($L{namelen}, 32, 'a region name is 32 bytes including the NUL');

is($L{word}, $Config::Config{ptrsize} || $L{word},
   'the recorded pointer width is this build\'s')
    if eval { require Config; 1 };

# The header and the registry entry both live at the front of every region, and
# both are read by processes that did not write them.
cmp_ok($L{header}, '>', 0, 'the header has a size');
cmp_ok($L{reg}, '>', $L{namelen},
       'a registry entry is bigger than the name it holds');

# A registry entry must not need padding the two builds might disagree about:
# it is an array, so a stride mismatch would put every entry after the first at
# a different place in each process.
is($L{reg} % 8, 0, 'a registry entry is a multiple of 8, so the array strides '
                 . 'identically in every build that shares it');

done_testing;
