#!/usr/bin/perl

# Unit tests for the PITA::XML::Test class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 33;
use PITA::XML ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}





#####################################################################
# Testing a sample of the functionality

# Test an ordinary object
SCOPE: {
	my $test = PITA::XML::Test->new(
		name     => 'foo',
		language => 'text/plain',
		stdout   => \"1..0\n",
		stderr   => \"",
		exitcode => 0,
		);
	isa_ok( $test, 'PITA::XML::Test' );
	is( $test->name, 'foo', '->name returns as expected' );
	is( $test->language, 'text/plain', '->language returns as expected' );
	is_deeply( $test->stdout, \"1..0\n", '->stdout returns as expected' );
	is_deeply( $test->stderr, \"", '->stderr returns as expected' );
	is( $test->exitcode, 0, '->exitcode returns as expected' );
}



# Test a minimal object
SCOPE: {
	my $test = PITA::XML::Test->new(
		stdout   => \"1..1\nok 1 test is ok\n",
		);
	isa_ok( $test, 'PITA::XML::Test' );
	is( $test->name, undef, '->name returns as expected' );
	is( $test->language, 'text/x-tap', '->language returns as expected' );
	is_deeply( $test->stdout, \"1..1\nok 1 test is ok\n", '->stdout returns as expected' );
	is_deeply( $test->stderr, undef, '->stderr returns as expected' );
	is( $test->exitcode, undef, '->exitcode returns as expected' );
}





#####################################################################
# Bad STDOUT

dies(
	sub { PITA::XML::Platform->new },
	'->new dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stdout => undef,
	) },
	'->stdout(undef) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stdout => '',
	) },
	'->stdout("") dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stdout => "1..1\nok\n",
	) },
	'->stdout(valid but non-ref) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stdout => [],
	) },
	'->stdout(ARRAY) dies as expected',
);





#####################################################################
# Bad name

dies(
	sub { PITA::XML::Platform->new(
		name   => undef,
		stdout => \"1..1\nok\n",
	) },
	'->name(undef) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		name   => '',
		stdout => \"1..1\nok\n",
	) },
	'->name("") dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		name   => \"",
		stdout => \"1..1\nok\n",
	) },
	'->name(SCALAR) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		name   => [],
		stdout => \"1..1\nok\n",
	) },
	'->name(ARRAY) dies as expected',
);





#####################################################################
# Bad language

dies(
	sub { PITA::XML::Platform->new(
		language => undef,
		stdout   => \"1..1\nok\n",
	) },
	'->language(undef) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		language => '',
		stdout   => \"1..1\nok\n",
	) },
	'->language("") dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		language => \"",
		stdout   => \"1..1\nok\n",
	) },
	'->language(SCALAR) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		language => [],
		stdout   => \"1..1\nok\n",
	) },
	'->language(ARRAY) dies as expected',
);





#####################################################################
# Bad STDERR

dies(
	sub { PITA::XML::Platform->new(
		stderr => undef,
		stdout   => \"1..1\nok\n",
	) },
	'->stderr(undef) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stderr => '',
		stdout   => \"1..1\nok\n",
	) },
	'->stderr("") dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stderr => "1..1\nok\n",
		stdout   => \"1..1\nok\n",
	) },
	'->stderr(valid but non-ref) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		stderr => [],
		stdout   => \"1..1\nok\n",
	) },
	'->stderr(ARRAY) dies as expected',
);





#####################################################################
# Bad exit code

dies(
	sub { PITA::XML::Platform->new(
		exitcode => undef,
		stdout   => \"1..1\nok\n",
	) },
	'->exitcode(undef) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		exitcode => '',
		stdout   => \"1..1\nok\n",
	) },
	'->exitcode("") dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		exitcode => \"",
		stdout   => \"1..1\nok\n",
	) },
	'->exitcode(SCALAR) dies as expected',
);

dies(
	sub { PITA::XML::Platform->new(
		exitcode => [],
		stdout   => \"1..1\nok\n",
	) },
	'->exitcode(ARRAY) dies as expected',
);

exit(0);
