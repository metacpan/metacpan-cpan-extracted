#!perl

use strict;
use warnings;

use Overload::FileCheck qw{mock_file_check unmock_file_check unmock_all_file_checks :check};
use Errno ();

# all -f checks will be true from now
mock_file_check( '-f' => sub { 1 } );

# mock all calls to -e and delegate to the function dash_e
mock_file_check( '-e' => \&dash_e );

# example of your own callback function to mock -e
# when returning
#  0: the test is false
#  1: the test is true
# -1: you want to use the answer from Perl itself :-)

sub dash_e {
    my ($file_or_fh) = @_;

    # return true on -e for this specific file
    return CHECK_IS_TRUE
      if $file_or_fh eq '/this/file/is/not/there/but/act/like/if/it/was';

    # claim that /tmp is not available even if it exists
    if ( $file_or_fh eq '/tmp' ) {

        # you can set Errno to any custom value
        #   or it would be set to Errno::ENOENT() by default
        $! = Errno::ENOENT();    # set errno to "No such file or directory"
        return CHECK_IS_FALSE;
    }

    # delegate the answer to the Perl CORE -e OP
    #   as we do not want to control these files
    return FALLBACK_TO_REAL_OP;
}

# unmock -e and -f
unmock_file_check('-e');
unmock_file_check('-f');
unmock_file_check(qw{-e -f});

# or unmock all existing filecheck
unmock_all_file_checks();
