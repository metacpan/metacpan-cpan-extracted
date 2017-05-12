# -*- perl -*-

#use Test::More tests => 13;
use Test::More 'no_plan';

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

close STDIN or warn $!;		# query noninteractively.

ok $t->ask,			 "ask()";

unlink "MyConfig.pm";
die "Can't continue, MyConfig.pm is in the way. Please delete it"
    if -e $t->file;

ok $t->save,			 "save()";
ok -r "MyConfig.pm",		 "MyConfig.pm was written";
ok require "MyConfig.pm",	 "require 'MyConfig.pm'";
ok $m = MyConfig->new,		 "MyConfig->new()";
is $m->one, 1,			 "one() == 1";
is $m->two, 2,			 "two() == 2";
is $m->three, 3,		 "three() == 3";
is $m->four, 4,			 "four() == 4";
is $m->testconfig_five, 5,	 "five() == 5";
ok ! eval { $m->dne },	 	 "dne(), a nonexistent method";

like $t->report, qr/one.*\b1\b/m,	"report 1";
like $t->report, qr/two.*\b2\b/m,	"report 2";
like $t->report, qr/three.*\b3\b/m,	"report 3";
like $t->report, qr/four.*\b4\b/m,	"report 4";
like $t->report, qr/five.*\b5\b/m,	"report 5";
