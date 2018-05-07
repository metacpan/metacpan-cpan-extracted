#
# Test file for Test::Conditions
#
# 02-conditions.t - check that we can set, clear, and test conditions.

use strict;
use lib 'lib';

use Test::More tests => 6;

use List::Util qw(any none);

use Test::Conditions;


# First check that we can actually instantiate this module.

my $tc = new_ok( 'Test::Conditions' ) || BAIL_OUT;


# Now try setting, clearing, flagging, and decrementing some conditions and check that the proper
# tests pass.

subtest 'negative conditions' => sub {

    $Test::Conditions::TEST_DIAG = '';
    
    $tc = Test::Conditions->new;
    
    $tc->clear('foo');
    
    $tc->ok_all('cleared condition');
    
    $tc->reset_conditions;
    
    $tc->set('bar');
    $tc->clear('bar');
    
    $tc->ok_all('cleared condition after set');
    
    $tc->reset_conditions;
    
    $tc->flag('foo', 'aaa');
    $tc->clear('foo');
    
    $tc->ok_all('cleared condition after flag');
    
    $tc->reset_conditions;
    
    $tc->set('baz');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('set condition');
    }

    like($Test::Conditions::TEST_DIAG, qr{'baz'}, 'got proper diagnostic message');
    
    $tc->reset_conditions;
    
    $tc->flag('biff', 'bbb');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;

	$tc->ok_all('flagged condition');
    }
    
    like($Test::Conditions::TEST_DIAG, qr{'biff'}, 'got proper diagnostic message');
    like($Test::Conditions::TEST_DIAG, qr{\[bbb\]}, 'got proper diagnostic label');
};


subtest 'multiple flags' => sub {
    
    $tc = Test::Conditions->new;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo', 'aaa');
    $tc->flag('foo', 'bbb');
    $tc->flag('bar', 'ccc');

    ok( ! $tc->is_tested('foo'), "condition 'foo' is not yet tested" );
    ok( ! $tc->is_tested('bar'), "condition 'bar' is not yet tested" );
    ok( ! $tc->is_tested('baz'), "condition 'baz' is not yet tested" );
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('multiply flagged conditions');
    }
    
    like($Test::Conditions::TEST_DIAG, qr{'foo'.*2 instances.*\[aaa\]}, "diag proper label for 'foo'");
    like($Test::Conditions::TEST_DIAG, qr{'bar'.*1 instance .*\[ccc\]}, "diag proper label for 'bar'");
    unlike($Test::Conditions::TEST_DIAG, qr{bbb}, "diag extra label not found");
    
    is( $tc->get_count('foo'), 2, "got proper count for 'foo'");
    is( $tc->get_label('foo'), 'aaa', "got proper label for 'foo'");
    ok( $tc->is_set('foo'), "condition 'foo' is set");
    ok( $tc->is_tested('foo'), "condition 'foo' is tested" );
    is( $tc->get_count('bar'), 1, "got proper count for 'bar'");
    is( $tc->get_label('bar'), 'ccc', "got proper label for 'bar'");
    ok( $tc->is_set('bar'), "condition 'bar' is set");
    ok( $tc->is_tested('bar'), "condition 'bar' is tested" );
    ok( ! $tc->is_set('baz'), "condition 'baz' is not set");
    ok( ! $tc->is_tested('baz'), "condition 'baz' is not tested");
    
    $tc->reset_conditions;
    
    $tc->flag('foo', 'ddd');
    $tc->flag('foo', 'eee');
    $tc->flag('foo', 'fff');
    $tc->decrement('foo', 'ddd');
    $tc->decrement('foo', 'eee');
    $tc->decrement('foo', 'fff');
    
    $tc->ok_all('flagged and decremented condition');
    
    is( $tc->get_count('foo'), '0', "got proper count for 'foo'" );
    is( $tc->get_label('foo'), '', "got proper label for 'foo'" );
    ok( ! $tc->is_set('foo'), "condition 'foo' is not set" );
    ok( ! $tc->is_tested('foo'), "condition 'foo' is not tested" );
    
    $tc->reset_conditions;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo', 'ggg');
    $tc->flag('foo', 'hhh');
    $tc->flag('bar', 'hhh');
    
    is( $tc->get_label('foo'), 'ggg', "got proper label for 'foo' after reset" );
    
    $tc->decrement('foo');
    $tc->decrement('foo');
    
    is( $tc->get_label('foo'), '', "got proper label for 'foo' after decrement" );
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;

	$tc->ok_all('one condition decremented, the other still active');
    }
    
    unlike($Test::Conditions::TEST_DIAG, qr{'foo'}, "diag did not show 'foo'");
    like($Test::Conditions::TEST_DIAG, qr{'bar'}, "diag showed 'bar'");

    # Now try ok_all one more time and check that tested conditions are counted as not being set.

    $tc->ok_all('all conditions have already been tested');
};


subtest 'positive conditions' => sub {
    
    $tc = Test::Conditions->new;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->expect('foo', 'bar');
    
    $tc->flag('foo', 'aaa');
    $tc->set('bar');

    $tc->ok_all('expected conditions');
    
    $tc->reset_conditions;

    $tc->set('foo');

    {
	local($Test::Conditions::TEST_INVERT) = 1;

	$tc->ok_all('missing condition');
    }

    like($Test::Conditions::TEST_DIAG, qr{'bar'}, "'diag showed 'bar'");
    unlike($Test::Conditions::TEST_DIAG, qr{'foo'}, "'diag did not show 'foo'");
    
    $tc->reset_conditions;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->set('foo');
    $tc->set('bar');
    $tc->clear('foo');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('cleared condition');
    }
    
    like($Test::Conditions::TEST_DIAG, qr{'foo'}, "'diag showed 'foo'");
    unlike($Test::Conditions::TEST_DIAG, qr{'bar'}, "'diag did not show 'bar'");
    
    $tc->reset_conditions;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo', 'aaa');
    $tc->flag('foo', 'bbb');
    $tc->flag('bar', 'ccc');

    $tc->ok_all('expected and flagged conditions');

    $tc->reset_conditions;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo', 'aaa');
    $tc->flag('foo', 'bbb');
    $tc->decrement('foo');
    $tc->decrement('foo');
    $tc->flag('bar', 'ccc');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('decremented condition');
    }
    
    like( $Test::Conditions::TEST_DIAG, qr{'foo'}, "'diag showed 'foo'" );
    unlike( $Test::Conditions::TEST_DIAG, qr{'bar'}, "'diag did not show 'bar'" );

    # Now try calling ok_all twice, and check that it fails the second time.

    $tc->reset_conditions;
    
    $tc->set('foo');
    $tc->set('bar');

    $tc->ok_all("both expected conditions are set");

    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all("the expected conditions have previously been tested");
    }
};


# Now test that the methods for returning lists of condition keys produce the proper results.

subtest 'keys' => sub {
    
    $tc = Test::Conditions->new;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->expect('foo', 'bar');

    $tc->set('baz');
    $tc->flag('biff');
    $tc->flag('biff', 'a1');
    $tc->set('buzz');
    $tc->clear('buzz');
    $tc->clear('baffle');
    $tc->flag('bick');
    $tc->decrement('bick');
    
    my @active = $tc->active_conditions;
    my @expected = $tc->expected_conditions;
    my @all = $tc->all_conditions;

    ok( (any { /baz/ } @active), "active has 'baz'" );
    ok( (any { /biff/ } @active), "active has 'biff'" );
    is( scalar(@active), 2, "active has two elements" );

    ok( (any { /foo/ } @expected), "expected has 'foo'" );
    ok( (any { /bar/ } @expected), "expected has 'bar'" );
    is( scalar(@expected), 2, "expected has two elements" );

    ok( (any { /baz/ } @all), "all has 'baz'" );
    ok( (any { /biff/ } @all), "all has 'biff'" );
    ok( (any { /buzz/ } @all), "all has 'buzz'" );
    ok( (any { /baffle/ } @all), "all has 'baffle'" );
    ok( (any { /bick/ } @all), "all has 'bick'" );
    is( scalar(@all), 5, "all has five elements" );

    $tc->clear('biff');
    ok( (none { /biff/ }, $tc->active_conditions), "active no longer has 'biff'" );
};


# Now make sure that ok_condition and ok_all work properly together.

subtest 'ok_condition' => sub {
    
    $tc = Test::Conditions->new;

    $tc->flag('foo');
    $tc->flag('bar');
    
    $tc->ok_condition('baz', "baz is not set");
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
        $tc->ok_condition('foo', "foo is set");
	
	$Test::Conditions::TEST_DIAG = '';

	$tc->ok_all("bar is still set");

	like( $Test::Conditions::TEST_DIAG, qr{'bar'}, "diag shows 'bar'" );
    }
    
    $tc->ok_condition('foo', "foo has been tested");
    ok( $tc->is_set('foo'), "foo is still set" );

    $tc = Test::Conditions->new;

    $tc->expect('foo');

    $tc->flag('foo');

    $tc->ok_all('expected condition is set');

    {
        local($Test::Conditions::TEST_INVERT) = 1;

	$tc->ok_condition('foo', "expected condition has been tested");
    }
};


