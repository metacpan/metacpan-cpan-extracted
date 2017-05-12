#!perl

# $Id: FSM-import.t,v 1.1 2011/04/16 20:20:44 Paulo Exp $

use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture';

my($stdout, $stderr, $ok);

#------------------------------------------------------------------------------
# fails with missing arguments
unlink 'Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM -);
};
is $stdout, "";
is $stderr, "Usage: perl -MParse::FSM - GRAMMAR MODULE::NAME [MODULE/NAME.pm]\n";
ok !$ok;
ok ! -f 'Parser.pm';

#------------------------------------------------------------------------------
# fails with missing arguments
unlink 'Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM - t/Data/calc.yp);
};
is $stdout, "";
is $stderr, "Usage: perl -MParse::FSM - GRAMMAR MODULE::NAME [MODULE/NAME.pm]\n";
ok !$ok;
ok ! -f 'Parser.pm';

#------------------------------------------------------------------------------
# fails with too many arguments
unlink 'Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM - t/Data/calc.yp mod file x);
};
is $stdout, "";
is $stderr, "Usage: perl -MParse::FSM - GRAMMAR MODULE::NAME [MODULE/NAME.pm]\n";
ok !$ok;
ok ! -f 'Parser.pm';

#------------------------------------------------------------------------------
# Create with default file
unlink 'Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM - 
						   t/Data/calc.yp Parser);
};
is $stdout, "";
is $stderr, "";
ok $ok;
ok -f 'Parser.pm';

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib Parser.pm 1+2;2+3*4);
};
is $stdout, "[3, 14]\n";
is $stderr, "";
ok $ok;

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParser -e),
						'$x=Parser->new->run(shift);print(join(q/,/,@$x))',
						'1+2;2+3*4';
};
is $stdout, "3,14";
is $stderr, "";
ok $ok;
ok unlink 'Parser.pm';

#------------------------------------------------------------------------------
# Create with default file in subdir
unlink 't/Data/Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM - 
						   t/Data/calc.yp t::Data::Parser);
};
is $stdout, "";
is $stderr, "";
ok $ok;
ok -f 't/Data/Parser.pm';

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib t/Data/Parser.pm 1+2;2+3*4);
};
is $stdout, "[3, 14]\n";
is $stderr, "";
ok $ok;

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -Mt::Data::Parser -e),
				'$x=t::Data::Parser->new->run(shift);print(join(q/,/,@$x))',
				'1+2;2+3*4';
};
is $stdout, "3,14";
is $stderr, "";
ok $ok;
ok unlink 't/Data/Parser.pm';

#------------------------------------------------------------------------------
# Create with supplied file name
unlink 't/Data/Parser.pm';
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -MParse::FSM - 
						   t/Data/calc.yp Parser t/Data/Parser.pm);
};
is $stdout, "";
is $stderr, "";
ok $ok;
ok -f 't/Data/Parser.pm';

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib t/Data/Parser.pm 1+2;2+3*4);
};
is $stdout, "[3, 14]\n";
is $stderr, "";
ok $ok;

# use the generated parser
($stdout, $stderr) = capture {
	$ok = ! system $^X, qw(-Iblib/lib -It/Data -MParser -e),
				'$x=Parser->new->run(shift);print(join(q/,/,@$x))',
				'1+2;2+3*4';
};
is $stdout, "3,14";
is $stderr, "";
ok $ok;
ok unlink 't/Data/Parser.pm';

#------------------------------------------------------------------------------
done_testing;
