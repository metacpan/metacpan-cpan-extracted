#!perl -T
use warnings;
use strict;

use Test::More tests => 3;

use lib qw( t t/lib ./lib );
use OEmployee;
BEGIN { inherit OEmployee }


is( check_setting_inherited_members(), 'OK',  'Setting of inherited members');
is( check_setting_redefined_members(), 'OK',  'Setting of redefined members');

is( check_inpackage_code(), 'OK', 'In package code. vars visibility');

exit;


######################################################################

# check that member inheritance is C++ like, i.e. setting the child class
# value also sets the parent class value
sub check_setting_inherited_members {
    eval {
        $OEmployee::USERNAME_mk_st = '_user_name_';
        _check_values( $OEmployee::USERNAME_mk_st => '_user_name_',
                       $OWorker::USERNAME_mk_st   => '_user_name_',
                       $OPerson::USERNAME_mk_st   => '_user_name_',
                     );
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

# Check that member inheritance is C++ like, i.e. setting a redefined child
#  class member leaves the parent class member unaffected
sub check_setting_redefined_members {
    eval {
        _check_values( $OPerson::COMMON_NAME   => 'COMMON_NAME',
                     );
        $OEmployee::COMMON_NAME = '_employee_name_';
        _check_values( $OEmployee::COMMON_NAME => '_employee_name_',
                       $OPerson::COMMON_NAME   => 'COMMON_NAME',
                       $OWorker::COMMON_NAME   => 'COMMON_NAME',
                     );

        @OEmployee::USERNAME_mk_st = ('USERNAME', 'EMPLOYEENAME');
        _check_values( \@OEmployee::USERNAME_mk_st => ['USERNAME', 'EMPLOYEENAME'],
                       \@OWorker::USERNAME_mk_st   => ['USERNAME', 'EMPLOYEENAME'],
                       \@OPerson::USERNAME_mk_st   => ['USERNAME', 'USERNAME'],
                     );
        @OPerson::USERNAME_mk_st = ('USERNAME', 'PERSONNAME');
        _check_values( \@OEmployee::USERNAME_mk_st => ['USERNAME', 'EMPLOYEENAME'],
                       \@OWorker::USERNAME_mk_st   => ['USERNAME', 'EMPLOYEENAME'],
                       \@OPerson::USERNAME_mk_st   => ['USERNAME', 'PERSONNAME'],
                     );
        @OWorker::USERNAME_mk_st = ('USERNAME', 'WORKERNAME');
        _check_values( \@OEmployee::USERNAME_mk_st => ['USERNAME', 'WORKERNAME'],
                       \@OWorker::USERNAME_mk_st   => ['USERNAME', 'WORKERNAME'],
                       \@OPerson::USERNAME_mk_st   => ['USERNAME', 'PERSONNAME'],
                     );
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

# Check that variables can be referred to without package prefix
# and with package prefix
sub check_inpackage_code {
    {
        package OEmployee;
our $SALARY; # this would require use vars '$SALARY'
        my $check1 = main::_check_values( $SALARY => 'salary' );
        return $check1 if $check1 ne 'OK';
    }
    {
        package OWorker;
#        @USERNAME_mk_st;
    }

    my $check2 = _check_values( $OEmployee::SALARY => 'salary' );
    return $check2;
}


######################################################################
# TEST UTILITIES

sub _check_values {
    #my ($check_list) = @_;
    while (@_) {
        my ($key, $check) = (shift, shift);
        if (ref $key eq 'ARRAY') {
            _check_list_value($key, $check);
        }
        elsif (not ref $key) {
            _check_scalar_value($key, $check);
        }
        else {
            die "Don't know how to compare $key and $check\n";
        }
    }
    return 'OK';
}

sub _check_scalar_value {
    my ($value1, $value2) = @_;
    return if $value1 eq $value2;
    die "'$value1' is not equal to $value2\n";
}

sub _check_list_value {
    my ($list1, $list2) = @_;
    my $i = 0;
    while ($list1->[$i] or $list2->[$i]) {
        next if $list1->[$i] eq $list2->[$i++];
        die "List [@$list1] is not equal to [@$list2]\n";
    }
}

