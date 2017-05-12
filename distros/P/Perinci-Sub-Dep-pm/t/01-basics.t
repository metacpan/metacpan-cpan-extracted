#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More 0.98;

use Perinci::Sub::DepChecker qw(check_deps);
use Perinci::Sub::Dep::pm;

# BEGIN copy-pasted from Perinci::Sub::Wrapper's test script
sub test_check_deps {
    my %args = @_;
    my $name = $args{name};
    my $res = check_deps($args{deps});
    if ($args{met}) {
        ok(!$res, "$name met") or diag($res);
    } else {
        ok( $res, "$name unmet");
    }
}

sub deps_met {
    test_check_deps(deps=>$_[0], name=>$_[1], met=>1);
}

sub deps_unmet {
    test_check_deps(deps=>$_[0], name=>$_[1], met=>0);
}
# END copy-pasted code

deps_met   {pm=>"TestDep"}, "pm 1";
deps_unmet {pm=>"TestDep >= 0.41"}, "pm 2";
deps_unmet {pm=>"NonExistingModule"}, "pm 3";

done_testing();
