#!perl -T
use warnings;
use strict;

use Test::More tests => 6;

use lib qw( t t/lib ./lib );
use OEmployee;
BEGIN { inherit OEmployee }

is( check_person_export_ok(),   'OK', 'OPerson::EXPORT_OK');
is( check_worker_export_ok(),   'OK', 'OWorker::EXPORT_OK');
is( check_employee_export_ok(), 'OK', 'OEmployee::EXPORT_OK');
#is_deeply(\@OWorker::EXPORT_OK, \@OPerson::EXPORT_OK,
#          "OWorker::EXPORT_OK should be the same as OPerson::EXPORT_OK");

is( check_person_export(),      'OK', 'OPerson::EXPORT');
is( check_worker_export(),      'OK', 'OWorker::EXPORT');
is( check_employee_export(),    'OK', 'OEmployee::EXPORT');

exit;


######################################################################

sub check_person_export_ok {
    return _check_export_list('$personfield_exp_ok', \@OPerson::EXPORT_OK, '@OPerson::EXPORT_OK');
}

sub check_person_export {
    # moved to EXPORT_INHERIT
    #return _check_export_list('$USERNAME_mk_st', \@OPerson::EXPORT, '@OPerson::EXPORT');
    return 'OK';
}

sub check_worker_export_ok {
#    return 'OK' if _lists_equal(\@OWorker::EXPORT_OK, \@OPerson::EXPORT_OK);
#    return "OWorker::EXPORT_OK is not the same as OPerson::EXPORT_OK";
    return _check_export_list('$DUMMY', \@OWorker::EXPORT_OK, '@OWorker::EXPORT_OK');
}

sub check_worker_export {
    return (scalar @OWorker::EXPORT == 0)
            ? 'OK' : "OWorker::EXPORT_OK is not empty @OWorker::EXPORT";
}

sub check_employee_export_ok {
    eval {
        _check_export_list('$someemployee', \@OEmployee::EXPORT_OK, '@OEmployee::EXPORT_OK');
        # This will fail unless someone inherits/imports from OEmployee
        _check_export_list('$SALARY', \@OEmployee::EXPORT_OK, '@OEmployee::EXPORT_OK');
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

sub check_employee_export {
    eval {
    };
    if ($@) { chomp $@; return $@ }
    return 'OK';
}

######################################################################
# TEST UTILITIES

sub _check_export_list {
    my ($symbol, $export_list, $listname) = @_;

    return 'OK' if grep {$_ eq $symbol} @$export_list;
    die "Cannot find '$symbol' in $listname\n";
}


sub _lists_equal {
    my ($list1, $list2) = @_;
    no warnings;
    if ( (join '', @$list1) eq join('', @$list2) ) {
        return 1;
    }
    return 0;
}

