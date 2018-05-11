#
# Test file for Test::Conditions
#
# 02-conditions.t - check that we can set, clear, and test conditions.

use strict;
use lib 'lib';

use Test::More tests => 6;

use Test::Conditions;


# First check that we can actually instantiate this module.

my $tc = new_ok( 'Test::Conditions' ) || BAIL_OUT;


# Check that minimum limits work properly.

subtest 'minimum' => sub {
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc = Test::Conditions->new;
    
    $tc->expect('foo');
    $tc->expect_min(bar => 3);
    
    $tc->flag('foo');
    $tc->flag('bar');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('minimum not attained');
    }
    
    like( $Test::Conditions::TEST_DIAG, qr{'bar'.*expected at least 3}, "'diag showed 'bar'" );
    
    $tc->reset_conditions;
    
    foreach my $i ( 1..3 )
    {
	$tc->flag('foo', $i);
	$tc->flag('bar', $i);
    }
    
    $tc->ok_all('minimum exceeded for all conditions');

    # Now check that 'set' is not enough if a minimum larger than 1 is specified.

    $Test::Conditions::TEST_DIAG = '';
    
    $tc->reset_conditions;

    $tc->set('foo');
    $tc->set('bar');

    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('set does not fulfill minimum');
    }
    
    like( $Test::Conditions::TEST_DIAG, qr{'bar'.*expected at least 3}, "diag shows 'bar'" );
    unlike( $Test::Conditions::TEST_DIAG, qr{'foo'}, "diag does not show 'foo'" );
};


# Check that maximum limits work properly

subtest 'maximum' => sub {
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc = Test::Conditions->new;
    
    $tc->limit_max('foo' => 3);

    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');

    {
	local($Test::Conditions::TEST_OUTPUT) = 1;
	
	$tc->ok_all('maximum not exceeded');
    }

    like( $Test::Conditions::TEST_DIAG, qr{warnings}, "diag shows warnings" );
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*3 instances.*limit 3}, "diag shows proper limit" );
    
    # This next set of statements is testing that 'reset_conditions' is not really needed, and you
    # can simply reuse an instance after calling 'ok_all' on it.
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo');
    
    {
	local($Test::Conditions::TEST_OUTPUT) = 1;
	
	$tc->ok_all('maximum still not exceeded');
    }

    like( $Test::Conditions::TEST_DIAG, qr{warnings}, "diag shows warnings" );
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*1 instance[^s].*limit 3}, "diag shows proper limit" );    
    
    # Now we will make sure that the maximum is exceeded.
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('maximum is exceeded');
    }
    
    unlike( $Test::Conditions::TEST_DIAG, qr{warnings}, "diag shows no warnings" );
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*4 instances}, "diag shows proper count" );
};


# Check that minimum and maximum limits work properly together.

subtest 'both' => sub {
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc = Test::Conditions->new;

    $tc->expect_min('foo' => 2);
    $tc->limit_max('foo' => 3);
    
    $tc->flag('foo');
    $tc->flag('foo');
    
    {
	local($Test::Conditions::TEST_OUTPUT) = 1;
	
	$tc->ok_all('flagged twice is okay');
    }
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');

    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_OUTPUT) = 1;
	
	$tc->ok_all('flagged three times is okay');
    }
    
    $tc->flag('foo');
    
    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('flagged once is not enough');
    }

    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*expected at least 2}, "diag shows minimum limit" );
    
    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('not flagged at all fails');
    }

    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*no instances}, "diag indicates no instances" );    
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*expected.*2}, "diag indicates minimum limit" );    
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    
    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('flagged four times is too many');
    }

    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*limit 3}, "diag shows maximum limit" );
};


# Now do the same check for ok_condition.

subtest 'ok_condition both' => sub {
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc = Test::Conditions->new;
    
    $tc->expect_min('foo' => 2);
    $tc->limit_max('foo' => 3);
    
    $tc->flag('foo');
    $tc->flag('foo');
    
    $tc->ok_condition('foo', 'flagged twice is okay');
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    
    $tc->ok_condition('foo', 'flagged three times is okay');

    $tc->flag('foo');
    
    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_condition('foo', 'flagged once is not enough');
    }
    
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*expected at least 2}, "diag shows minimum limit" );
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('foo');
    
    $Test::Conditions::TEST_DIAG = '';
    
    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_condition('foo', 'flagged four times is too many');
    }

    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*limit 3}, "diag shows maximum limit" );
};


# Now check that we can set minimum and maximum limits for multiple conditions using hashrefs.

subtest 'hashrefs' => sub {
    
    $tc = Test::Conditions->new;
    
    $tc->expect_min( { foo => 2, 'bar a' => 2 } );
    
    $tc->flag('foo');
    $tc->flag('foo');
    $tc->flag('bar a');
    $tc->flag('bar a');
    
    $tc->ok_all('minimum limits reached');
    
    $tc->reset_conditions;
    
    $Test::Conditions::TEST_DIAG = '';
    
    $tc->flag('foo');
    $tc->flag('bar a');

    {
	local($Test::Conditions::TEST_INVERT) = 1;
	
	$tc->ok_all('minimum limits not reached');
    }

    like( $Test::Conditions::TEST_DIAG, qr{'foo'}, "diag found 'foo'" );
    like( $Test::Conditions::TEST_DIAG, qr{'bar a'}, "diag found 'bar a'" );

    $tc = Test::Conditions->new;

    $Test::Conditions::TEST_DIAG = '';
    
    $tc->limit_max( { foo => 3, bar => 2 } );
    
    $tc->flag('foo');
    $tc->flag('bar');
    
    {
	local($Test::Conditions::TEST_OUTPUT) = 1;
	
        $tc->ok_all('maximum limits not exceeded');
    }
    
    like( $Test::Conditions::TEST_DIAG, qr{warnings}, "diag found warnings" );
    like( $Test::Conditions::TEST_DIAG, qr{'foo'.*limit 3}, "diag found limit for 'foo'" );
    like( $Test::Conditions::TEST_DIAG, qr{'bar'.*limit 2}, "diag found limit for 'bar'" );
};
