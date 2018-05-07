#
# Test file for Test::Conditions
#
# 01-basic.t - test that the module loads properly and can be instantiated.

use lib 'lib';

use strict;
use Test::More tests => 8;

BEGIN {
    use_ok( 'Test::Conditions' ) || print "Bail out!\n";
}

diag( "Testing Test::Conditions $Test::Conditions::VERSION, Perl $], $^X" );

# First check that we can actually instantiate this module.

my $tc = new_ok( 'Test::Conditions' ) || BAIL_OUT;


# Then check that none of the instance methods crash.

subtest 'setting and clearing' => sub {

    eval {
	$tc->set('foo');
	$tc->set('bar');
	$tc->clear('bar');
	$tc->clear('baz');
    };
    
    unless ( ok( ! $@, "no errors from 'set' and 'clear'" ) )
    {
	diag("Error was: $@");
    }
    
    eval {
	$tc->flag('aaa', 'test 1');
	$tc->flag('bbb', 'test 2');
	$tc->decrement('bbb', 'test 2');
    };
    
    unless ( ok( ! $@, "no errors from 'flag' and 'decrement'" ) )
    {
	diag("Error was: $@");
    }
};


subtest 'expects and limits' => sub {
    
    eval {
	$tc->expect('abc', 'def');
	$tc->expect_min(ghi => 3);
	$tc->limit_max(jkl => 4);
    };

    unless ( ok( ! $@, "no errors from expect and limit methods" ) )
    {
	diag("Error was: $@");
    }
};


subtest 'conditions' => sub {

    eval {
	my @active = $tc->active_conditions;
	my @expected = $tc->expected_conditions;
	my @all = $tc->all_conditions;
    };

    unless ( ok( ! $@, "no errors from condition list methods" ) )
    {
	diag("Error was: $@");
    }
};


subtest 'accessors' => sub {
    
    eval {
	my $tested = $tc->is_tested('foo');
	my $active = $tc->is_set('bar');
	my $count = $tc->get_count('aaa');
	my $label = $tc->get_label('bbb');
    };

    unless ( ok( ! $@, "no errors from accessor methods" ) )
    {
	diag("Error was: $@");
    }
};


subtest 'reset' => sub {

    eval {
	$tc->reset_condition('foo');
	$tc->reset_conditions;
    };
    
    unless ( ok( ! $@, "no errors from reset methods" ) )
    {
	diag("Error was: $@");
    }
};


subtest 'tests' => sub {
    
    # We need to create a new instance without any expected conditions so that we can execute a
    # test that is supposed to succeed.

    eval {
	my $tc2 = Test::Conditions->new;

	$tc2->ok_all("passed a vacuous test");
	$tc2->ok_condition('foo', "passed a vacuous test on a single condition");
    };
    
    unless ( ok( ! $@, "no errors from 'ok_all' or 'ok_condition'" ) )
    {
	diag("Error was: $@");
    }
};


