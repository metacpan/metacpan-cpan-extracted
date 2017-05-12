#!perl -T
use warnings;
use strict;

use Test::More tests => 6;

use lib qw( t t/lib ./lib );
use MEmployee;
BEGIN { inherit MEmployee }

is( check_person_export_ok(),   'OK', 'MPerson::EXPORT_OK');
is( check_worker_export_ok(),   'OK', 'MWorker::EXPORT_OK');
is( check_employee_export_ok(), 'OK', 'MEmployee::EXPORT_OK');
#is_deeply(\@MWorker::EXPORT_OK, \@MPerson::EXPORT_OK,
#          "MWorker::EXPORT_OK should be the same as MPerson::EXPORT_OK");

is( check_person_export(),      'OK', 'MPerson::EXPORT');
is( check_worker_export(),      'OK', 'MWorker::EXPORT');
is( check_employee_export(),    'OK', 'MEmployee::EXPORT');

exit;


######################################################################

sub check_person_export_ok {
    return _check_export_list('$personfield_exp_ok', \@MPerson::EXPORT_OK, '@MPerson::EXPORT_OK');
}

sub check_person_export {
    # moved to EXPORT_INHERIT
    #return _check_export_list('$USERNAME_mk_st', \@MPerson::EXPORT, '@MPerson::EXPORT');
    return 'OK';
}

sub check_worker_export_ok {
#    return 'OK' if _lists_equal(\@MWorker::EXPORT_OK, \@MPerson::EXPORT_OK);
#    return "MWorker::EXPORT_OK is not the same as MPerson::EXPORT_OK";
    return _check_export_list('$DUMMY', \@MWorker::EXPORT_OK, '@MWorker::EXPORT_OK');
}

sub check_worker_export {
    return (scalar @MWorker::EXPORT == 0)
            ? 'OK' : "MWorker::EXPORT_OK is not empty @MWorker::EXPORT";
}

sub check_employee_export_ok {
    eval {
        _check_export_list('$someemployee', \@MEmployee::EXPORT_OK, '@MEmployee::EXPORT_OK');
        # This will fail unless someone inherits/imports from MEmployee
        _check_export_list('$SALARY', \@MEmployee::EXPORT_OK, '@MEmployee::EXPORT_OK');
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

