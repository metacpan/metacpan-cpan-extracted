# -*- perl -*-

use Test::More tests => 9;
#use Test::More 'no_plan';

use Module::TestConfig::Question;

ok $q1 = Module::TestConfig::Question->new( [ qw/One? one 1/ ]
					  ), "new( [ ... ])";

ok $q2 = Module::TestConfig::Question->new( msg	  => 'One?',
					    name  => 'one',
					    default => 1,
					  ), "new( ... )";

ok $q3 = Module::TestConfig::Question->new( { msg     => 'One?',
					      name    => 'one',
					      default => 1,
					      opts => {  noecho	   => 1,
							 skip	   => 2,
							 validate  => 3,
						      },
					    }
					  ), "new( { ... opts => { ... } } )";

ok $q4 = Module::TestConfig::Question->new( { question => 'One?',
					      name => 'one',
					      def => 1,
					      options => {  noecho => 1,
							    skip => 2,
							    validate  => 3,
						      },
					    }
					  ), "aliases in new()";

ok $q1->opts( { noecho	  => 1,
		skip	  => 2,
		validate  => 3,
	      }
	    ),				"opts( { ... } )";

ok $q2->opts( noecho	=> 1,
	      skip	=> 2,
	      validate	=> 3,
	    ),				"opts( ... )";

is_deeply $q1, $q2,			"q1 eq q2";
is_deeply $q1, $q3,			"q1 eq q3";
is_deeply $q1, $q4,			"q1 eq q4";
