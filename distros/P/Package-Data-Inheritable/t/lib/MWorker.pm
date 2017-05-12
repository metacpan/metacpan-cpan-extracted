# Test class for 'method-like' interface
use warnings;
use strict;
package MWorker;

use base qw( MPerson );
BEGIN {
    inherit MPerson;

    MWorker->pkg_inheritable('$DUMMY' => 'dummy');      # new member
    MWorker->pkg_inheritable('$DUMMY2' => 'dummy2');    # new member (to be overriden)
    MWorker->pkg_inheritable('@COMMON_NAME' => ['COMMON_NAME', 'list']); # new member
    MWorker->pkg_inheritable('@USERNAME_mk_st' => ['USERNAME', 'WORKERNAME']);  # override member
};

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
