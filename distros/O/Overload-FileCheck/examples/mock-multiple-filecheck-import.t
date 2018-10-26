#!perl

use strict;
use warnings;

use Overload::FileCheck '-e' => \&my_dash_e, -f => sub { 1 }, ':check';

# example of your own callback function to mock -e
# when returning
#  0: the test is false
#  1: the test is true
# -1: you want to use the answer from Perl itself :-)

sub dash_e {
    my ($file_or_handle) = @_;

    # return true on -e for this specific file
    return CHECK_IS_TRUE if $file_or_handle eq '/this/file/is/not/there/but/act/like/if/it/was';

    # claim that /tmp is not available even if it exists
    return CHECK_IS_FALSE if $file_or_handle eq '/tmp';

    # delegate the answer to the Perl CORE -e OP
    #   as we do not want to control these files
    return FALLBACK_TO_REAL_OP;
}
