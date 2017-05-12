#!perl -T

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use lib 'lib';

use warnings FATAL => 'all';
use Test::More;
use Test::Warn;

plan tests => 1;

		use warnings FATAL => 'all';
		use lib 'lib';
		use Parse::Gnaw;

warnings_exist{


		rule('rule2', 
			'c', 
			call('what_am_i_doing'),
		);

} ["/call passed a nonexistent rulename/"], "check for nonexistent rule warning";


