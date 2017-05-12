# -*- perl -*-

use Test::More tests => 15;
#use Test::More 'no_plan';

use Module::TestConfig;

ok $t = Module::TestConfig->new( questions => [
					       [ qw/One? one 1/ ],
					       [ qw/Two? two 2/ ],
					      ],
				 answers => { one => 1,
					      two => 2,
					    },
			       ), "new( q & a )";

is $t->questions->[0]->msg, 'One?',	"q1 msg";
is $t->questions->[0]->name, 'one',	"q1 name";
is $t->questions->[0]->default, 1,	"q1 default";
is $t->questions->[1]->msg, 'Two?',	"q2 msg";
is $t->questions->[1]->name, 'two',	"q2 name";
is $t->questions->[1]->default, 2,	"q2 default";


is_deeply {$t->answers}, { one => 1,
			   two => 2,
			 },	 "answers() looks ok";

is $t->answer( 'one' ), 1,	 "answer(1)";
is $t->answer( 'two' ), 2,	 "answer(2)";
ok ! $t->answer( 'undef' ),	 "answer('undef')";

close STDIN or warn $!;		# query noninteractively.
ok $t->ask,			 "ask()";

is $t->answer( 'one' ), 1,	 "answer(1)";
is $t->answer( 'two' ), 2,	 "answer(2)";
ok ! $t->answer( 'undef' ),	 "answer('undef')";
