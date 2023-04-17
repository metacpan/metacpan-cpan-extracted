#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops mytempfile mytempdir/; # strict, warnings, Carp etc.
use t_TestCommon  # Test::More etc.
         qw/$verbose $silent $debug dprint dprintf
            bug checkeq_literal expect1 check 
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            string_to_tempfile
            @quotes/;
use t_SSUtils;

#TODO
#
#write something to 
#verify that insert_rows & delete_rows updates title_rx if needed
