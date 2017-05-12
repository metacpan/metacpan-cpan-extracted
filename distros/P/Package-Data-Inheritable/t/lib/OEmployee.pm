# Test class for 'our-like' interface
use warnings;
use strict;
package OEmployee;

use lib '../lib/';
use Package::Data::Inheritable;

use base qw(OWorker);
BEGIN {
    our @EXPORT_INHERIT = qw( $SALARY $COMMON_NAME );

    inherit OWorker;
}

our $SALARY      = 'salary';         # new member
our $COMMON_NAME = 'EMPLOYEE_NAME';  # redefine parent class member

our @EXPORT_OK = qw( $someemployee );  # symbols to export on request

# Check all members scope visibility
{
    no warnings "void"; # avoid 'Useless use of a variable in void context ... message'
    $USERNAME_mk_st;
    @USERNAME_mk_st;
    $SALARY;
    $DUMMY;
    $COMMON_NAME;
    @COMMON_NAME;
}


sub get_USERNAME_mk_st {
    return $USERNAME_mk_st;
}
sub get_SALARY {
    return $SALARY;
}
sub get_COMMON_NAME {
    return $COMMON_NAME;
}

1;
