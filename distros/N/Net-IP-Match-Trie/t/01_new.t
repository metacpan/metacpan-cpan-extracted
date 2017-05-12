use strict;
use Test::More;

require Net::IP::Match::Trie;
Net::IP::Match::Trie->import;
note("new");
my $obj = new_ok("Net::IP::Match::Trie");

# diag explain $obj

done_testing;
