# Test class for 'our-like' interface
use warnings;
use strict;
package OPerson;

use base qw( Package::Data::Inheritable );
BEGIN {
    #inherit Package::Data::Inheritable;
}

# Export by hand
our $personfield_exp_ok = 'personfield_ok';
our $personfield_exp    = 'personfield';
our @EXPORT    = qw( $personfield_exp    );  # symbols to export by default
our @EXPORT_OK = qw( $personfield_exp_ok );  # symbols to export on request

# static inheritable fields
our $COMMON_NAME    = 'COMMON_NAME';
our $USERNAME_mk_st = 'USERNAME';
our @USERNAME_mk_st = ('USERNAME', 'USERNAME');

# @COMMON_NAME exported but not defined

# this export should be moved to the BEGIN block if we override anything
our @EXPORT_INHERIT = qw( $USERNAME_mk_st @USERNAME_mk_st $COMMON_NAME @COMMON_NAME );

# check all members scope visibility
sub check_visibility {
    no warnings "void"; # avoid 'Useless use of a variable in void context ... message'
    $USERNAME_mk_st;
    $COMMON_NAME;
#    @COMMON_NAME;
    @USERNAME_mk_st;
}

1;
