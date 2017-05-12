#!/usr/bin/perl -w

use strict;
use Test::More tests => 27;

BEGIN {
    use_ok('Proc::BackOff::Random');
    use_ok('Proc::BackOff::Linear');
    use_ok('Proc::BackOff::Exponential');
}

for my $p qw | Random Linear Exponential | {
    my $package = "Proc::BackOff::$p";

    use_ok($package);
    can_ok($package, 'calculate_back_off');
}

sub test_package {
    my $obj = shift;

    $obj->reset();
    $obj->failure();

    is ($obj->failure_count(),1,"$obj: failure count");
    ok ($obj->delay() > 0,"$obj: has delay");
    $obj->success();
    is ($obj->failure_count(),0,"$obj: failure count");

    $obj->failure();
    $obj->failure();
    is ($obj->failure_count(),2,"$obj: failure count");
    ok ($obj->delay() > 0,"$obj: has delay");

    $obj->reset();
    $obj->max_timeout(1);
    for (1..1000) { $obj->failure(); }
    is ($obj->failure_count(),1000,"$obj: failure count");
    if ( $obj->isa('Proc::BackOff::Random') ) {
        ok ($obj->delay() < $obj->max_timeout(),"$obj: failure count");
    } else {
        is ($obj->delay(),$obj->max_timeout(),"$obj: failure count");
    }
}

my $obj;

# test number failures

diag('Errors expected');
$obj = Proc::BackOff::Random->new( { min => 'abc' } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Random->new( { min => 123 } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Random->new( { min => 123, max => 'abc' } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Random->new( { min => 123, max => 523 } );
ok (defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Random->new( { min => 2, max => 1 } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Random->new( { min => 'count', max => 'count' } );
$obj->failure(); # code coverage;
ok (defined $obj, 'testing invalid input');



$obj = Proc::BackOff::Linear->new( { } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Linear->new( { slope => 'abc' } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Linear->new( { slope => 2, b => 'zero' } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Linear->new( { slope => 2, b => 2, x => 'af' } );
ok (! defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Linear->new( { slope => 2, b => 2, x => 2 } );
ok (defined $obj, 'testing invalid input');

$obj = Proc::BackOff::Linear->new( { slope => 'count', b => 'count', x => 'count' } );
$obj->failure(); # code coverage;
ok (defined $obj, 'testing invalid input');



$obj = Proc::BackOff::Exponential->new( { } );
ok (! defined $obj, 'Object created');

$obj = Proc::BackOff::Exponential->new( { exponent => 'rodger' } );
ok (! defined $obj, 'Object created');

$obj = Proc::BackOff::Exponential->new( { exponent => 14 } );
ok (! defined $obj, 'Object created');

$obj = Proc::BackOff::Exponential->new( { exponent => 2, base => 'rodger' } );
ok (! defined $obj, 'Object created');

$obj = Proc::BackOff::Exponential->new( { exponent => 2, base => 3 } );
ok (defined $obj, 'Object created');

$obj = Proc::BackOff::Exponential->new( { exponent => 'count', base => 'count' } );
$obj->failure(); # code coverage;
ok (defined $obj, 'Object created');
