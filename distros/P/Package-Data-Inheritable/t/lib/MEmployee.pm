# Test class for 'method-like' interface
use warnings;
use strict;
package MEmployee;

#BEGIN { chdir 't' if -d 't' }
#use blib;
use lib '../lib/';

use base qw( MWorker );
BEGIN {
    MEmployee->pkg_inheritable('$COMMON_NAME' => 'EMPLOYEE_NAME');  # redefine parent member, before inherit
    inherit MWorker;
    MEmployee->pkg_inheritable('$DUMMY2' => 'dummy2_employee');     # redefine parent member, after inherit

    MEmployee->pkg_inheritable('$SALARY' => 'salary');  # new member
}

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
