#!perl

use strict;
use warnings;

use Overload::FileCheck q(:all);

mock_file_check( '-e' => \&my_dash_e );
mock_file_check( '-f' => sub { CHECK_IS_TRUE } );

sub dash_e {
    my ($file_or_fh) = @_;

    # return true on -e for this specific file
    return CHECK_IS_TRUE if $file_or_fh eq '/this/file/is/not/there/but/act/like/if/it/was';

    # claim that /tmp is not available even if it exists
    return CHECK_IS_FALSE if $file_or_fh eq '/tmp';

    # delegate the answer to the Perl CORE -e OP
    #   as we do not want to control these files
    return FALLBACK_TO_REAL_OP;
}
