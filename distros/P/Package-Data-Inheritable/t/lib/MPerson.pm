# Test class for 'method-like' interface
use strict;
use warnings;

package MPerson;
use base qw( Package::Data::Inheritable );
BEGIN {
    #inherit Package::Data::Inheritable;

    MPerson->pkg_inheritable('$COMMON_NAME'    => 'COMMON_NAME');
    MPerson->pkg_inheritable('$USERNAME_mk_st' => 'USERNAME');
    MPerson->pkg_inheritable('@COMMON_NAME');
    MPerson->pkg_inheritable('@USERNAME_mk_st' => ['USERNAME', 'USERNAME']);
};

# static inheritable fields
no warnings 'syntax'; # avoid 'Possible unintended interpolation of @ ... message'

## Export by hand
our $personfield_exp_ok = 'personfield_ok';
our $personfield_exp    = 'personfield';
our @EXPORT    = qw( $personfield_exp    );  # symbols to export by default
our @EXPORT_OK = qw( $personfield_exp_ok );  # symbols to export on request

# check all members scope visibility
sub check_visibility {
    no warnings "void"; # avoid 'Useless use of a variable in void context ... message'
    $USERNAME_mk_st;
    $COMMON_NAME;
    @USERNAME_mk_st;
}

1;

