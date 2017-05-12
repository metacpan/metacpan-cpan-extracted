#!perl -T
use warnings;
use strict;

use Test::More tests => 3;

use lib qw( t t/lib ./lib );
use OEmployee;
BEGIN { inherit OEmployee }

is( check_person_export_values(),   'OK',  'OPerson:: exported values');
is( check_worker_export_values(),   'OK',  'OWorker:: exported values');
is( check_employee_export_values(), 'OK',  'OEmployee:: exported values');

exit;


######################################################################

sub check_person_export_values {
    eval {
        _check_values( $OPerson::personfield_exp_ok => 'personfield_ok',
                       $OPerson::personfield_exp    => 'personfield', 
                       $OPerson::COMMON_NAME        => 'COMMON_NAME',
                       $OPerson::USERNAME_mk_st     => 'USERNAME',
                       \@OPerson::USERNAME_mk_st    => ['USERNAME', 'USERNAME'],
                     );
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

sub check_worker_export_values {
    eval {
        no warnings 'once';    # do not complain for "used only once: possible typo"
        _check_values( $OWorker::personfield_exp_ok => undef,
                       $OWorker::personfield_exp    => 'personfield',
                       $OWorker::COMMON_NAME        => 'COMMON_NAME',
                       \@OWorker::COMMON_NAME       => ['COMMON_NAME', 'list'],
                       $OWorker::USERNAME_mk_st     => 'USERNAME',
                       \@OWorker::USERNAME_mk_st    => ['USERNAME', 'WORKERNAME'],
                     );
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

sub check_employee_export_values {
    eval {
        _check_values( $OEmployee::SALARY          => 'salary',
                       $OEmployee::COMMON_NAME     => 'EMPLOYEE_NAME',
                       $OEmployee::DUMMY           => 'dummy',
                       $OEmployee::USERNAME_mk_st  => 'USERNAME',   # inherited
                       \@OEmployee::COMMON_NAME    => ['COMMON_NAME', 'list'],
                       \@OEmployee::USERNAME_mk_st => ['USERNAME', 'WORKERNAME'],
                       #$OEmployee::personfield_exp_ok => 'personfield', # (false) not inherited
                       #$OEmployee::personfield_exp_ok => 'personfield',
                     );
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}


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
    return if (not defined $value1 and not defined $value2);
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

