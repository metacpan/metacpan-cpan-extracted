# -*- perl -*-

use Test::More tests => 28;
#use Test::More 'no_plan';

use Test::Warn;
use Config::Auto;
use Module::TestConfig;

$ENV{TESTCONFIG_FIVE} ||= 5;

ok $t = Module::TestConfig->new( questions => [
					       [ qw/One?   one/      ],
					       [ qw/Two?   two/      ],
					       [ qw/Three? three x/  ],
					       [ qw/Four?  four  4/  ],
					       [ qw/Five?  testconfig_five  x/  ],
					      ],
				 order => [ qw/env defaults/ ],
				 defaults => 't/etc/defaults.config',
			       ), "new()";

# And this is intentional.
# close STDIN or warn $!;		# query noninteractively.

close STDIN or warn $!;

ok $t->ask,	"ask()";

is $t->answer( 'one' ), 1,	 "answer(1) from file";
is $t->answer( 'two' ), 2,	 "answer(2) from file";
is $t->answer( 'three' ), 3, "answer(3) from file";
is $t->answer( 'four' ), 4,	 "answer(4) from default";
is $t->answer( 'testconfig_five' ), 5,	 "answer(5) from env";

$t->{answers}{'bro:ken'} = 'broken';
is $t->answer( 'bro:ken' ), 'broken',		"bad answer set";

warnings_like
    { $t->save_defaults(file => 'test.conf') }
    { carped => "/Skipping bad key/ms" },
    "save_defaults()";

ok -r 'test.conf',				"wrote new defaults file";

ok $conf = Config::Auto::parse('test.conf'), 	"parse new defaults file";
is $conf->{one}, 1,	 			"answer(1) from test.conf";
is $conf->{two}, 2,	 			"answer(2) from test.conf";
is $conf->{three}, 3,	 			"answer(3) from test.conf";
is $conf->{four}, 4,	 			"answer(4) from test.conf";
is $conf->{testconfig_five}, 5,	 		"answer(5) from test.conf";
isnt $conf->{'bro:ken'}, 'broken',		"didn't write key with :";

delete $t->{answers}{'bro:ken'};
$t->{answers}{'bro=ken'} = 'broken';
is $t->answer( 'bro=ken' ), 'broken',		"bad answer set";

warnings_like
    { $t->save_defaults(file => 'test.conf', sep => '=') }
    { carped => "/^Skipping bad key/" },
    "save_defaults( sep => '=' )";

ok -r 'test.conf',				"wrote new defaults file";
ok -r 'test.conf.bak',				"old defaults file backed up";

ok $conf = Config::Auto::parse('test.conf'), 	"parse new defaults file";
is $conf->{one}, 1,	 			"answer(1) from test.conf";
is $conf->{two}, 2,	 			"answer(2) from test.conf";
is $conf->{three}, 3,	 			"answer(3) from test.conf";
is $conf->{four}, 4,	 			"answer(4) from test.conf";
is $conf->{testconfig_five}, 5,	 		"answer(5) from test.conf";
isnt $conf->{'bro=ken'}, 'broken',		"didn't write key with =";
