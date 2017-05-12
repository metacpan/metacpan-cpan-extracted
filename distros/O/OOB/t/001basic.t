BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'OOB' ); # just for the record
can_ok( 'OOB::function',qw(
 OOB_get
 OOB_set
 OOB_reset
) );
