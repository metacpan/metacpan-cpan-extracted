# -*-perl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01_load.t.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { 
    use_ok('Peptide::Pubmed');
    use_ok('Peptide::Kmers');
};
