#############################################
# Tests for Sysadm::Install/s fs_read/write_open
#############################################

use Test::More tests => 7;

use Sysadm::Install qw(:all);

is(snip("abc", 5), 
   "abc", "snip full len");

is(snip("abcdefghijklmn", 11), 
   "(14)[ab[snip=10]mn]", "snip minlen");

is(snip("abcdefghijklmn", 12), 
   "(14)[ab[snip=10]mn]", "snip minlen");

is(snip("a\tcdefghijklm\n", 12), 
   "(14)[a.[snip=10]m.]", "snip special char");

is(snip("a\tcdefghijklm\n", 14), 
   "a.cdefghijklm.", "exact len match");

is(snip("abc", 5, 1), 
   "abc", "snip full len and keep flag");

is(snip("a\tc", 5), 
   "a.c", "snip full len with unprintable chars");

