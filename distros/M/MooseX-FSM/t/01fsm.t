use Test::More tests => 19;
use Test::Exception;

use FindBin qw($Bin);
use File::Spec::Functions;

use Data::Dumper;

# Need to make this quite
package __TEST;
Test::More::use_ok ('MooseX::FSM');
package main;


# pull in the test libs
use lib catdir($Bin, "lib");
use_ok ('FSM_01');

sub test_fsm_no_method {
	my $fsm = shift;
	my $method = shift;

	throws_ok { $fsm->$method() }  qr/Can't locate object method "$method"/, "$method does not exist";
}

#{ # creation tests

	# negative tests
#	eval {
#		my $fsm = MooseX::FSM->new();
#	};
#	like (
#	isa_ok ($fsm, 'MooseX::FSM', "$fsm created ok");
#}

	my $expected_states = {
		state1 => {
			has_methods => [ "input1", "input2" ],
			not_methods => [ "input3", "input4", "input5" ],
		},
		state2 => {
			has_methods => [ "input1", "input2" ],
			not_methods => [ "input3", "input4", "input5" ],
		},
	};
{

	my $fsm = FSM_01->new(start_state => 'state1');
	isa_ok ($fsm, 'FSM_01', 'FSM_01 created okay');

	is($fsm->current_state(), undef, 'un-started object is undefined');
# state start tests
	is($fsm->start(), 'state1', 'start function returns start state');
	is($fsm->input1(), 'func_1', 'input1 correctly aliased');
	
	test_fsm_no_method $fsm, "input3";
	test_fsm_no_method $fsm, "input4";
	throws_ok { $fsm->input3() }  qr/Can't locate object method/, 'input3 does not exist';
	throws_ok { $fsm->input4() }  qr/Can't locate object method/, 'input4 does not exist';
	throws_ok { $fsm->input5() }  qr/Can't locate object method/, 'input5 does not exist';
	# input 2 is the transition function
	is($fsm->input2(), 'func_2', 'input2 correctly aliased');

# state2 tests
	is($fsm->current_state(), 'state2', 'input2 took fsm to state2' );
	
	test_fsm_no_method $fsm, "input1";
	test_fsm_no_method $fsm, "input2";
	test_fsm_no_method $fsm, "input4";
	is($fsm->input5(), 'anon', 'input5 does exist');
	# input 3 is the transition to state4
	is($fsm->input3(), "func_3", 'input3 does exist');

# state2 tests
# state3 tests
# state4 tests
}



