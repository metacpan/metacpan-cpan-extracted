# Test class for 'our-like' interface
use warnings;
use strict;
package OWorker;

use base qw(OPerson);
use Package::Data::Inheritable;

# st1 and st3 are equivalent to st2
# This is to check that the only reason to have EXPORT_INHERIT within the
# BEGIN block is to allow proper overriding

BEGIN {
    # declare our fields and overrides *before* inheriting
    our @EXPORT_INHERIT = qw( @USERNAME_mk_st );                      # st1
    #our @EXPORT_INHERIT = qw( $DUMMY @COMMON_NAME @USERNAME_mk_st ); # st2

    inherit OPerson;
}
our @EXPORT_INHERIT = qw( $DUMMY @COMMON_NAME );   # st3
our @USERNAME_mk_st = ('USERNAME', 'WORKERNAME');  # override member

our $DUMMY = 'dummy';                           # new member
our @COMMON_NAME    = ('COMMON_NAME', 'list');  # new member


# Check all members scope visibility
{
    no warnings "void"; # avoid 'Useless use of a variable in void context ... message'
    $USERNAME_mk_st;
    @USERNAME_mk_st;
    $DUMMY;
    $COMMON_NAME;
    @COMMON_NAME;
}

1;
