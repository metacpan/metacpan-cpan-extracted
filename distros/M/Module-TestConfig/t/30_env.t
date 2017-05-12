# -*- perl -*-

use Test::More tests => 6;
#use Test::More 'no_plan';

use Module::TestConfig;

$ENV{TESTCONFIG_ONE}	||= 1;
$ENV{TESTCONFIG_TWO}	||= 2;
$ENV{testconfig_three}	||= 3;
$ENV{testconfig_four}	||= 4;

ok $t = Module::TestConfig->new( questions => [
					       [ qw/One?   testconfig_one/   ],
					       [ qw/Two?   testconfig_two/   ],
					       [ qw/Three? testconfig_three/ ],
					       [ qw/Four?  testconfig_four/  ],
					      ],
				 order => [ 'env' ],
			       ), "new()";

close STDIN or warn $!;		# query noninteractively.

ok $t->ask,			 "ask()";

is $t->answer( 'testconfig_one' ), 1,	 "answer(1)";
is $t->answer( 'testconfig_two' ), 2,	 "answer(2)";
is $t->answer( 'testconfig_three' ), 3,	 "answer(3)";
is $t->answer( 'testconfig_four' ), 4,	 "answer(4)";

