#
#===============================================================================
#
#         FILE: wordlist.t
#
#  DESCRIPTION: Test of wordlist wrapper
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 15/08/19 15:04:05
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;
use Template::Plugin::Lingua::EN::Inflexion;

my $class  = 'Template::Plugin::Lingua::EN::Inflexion';
my @fruits = qw/apple orange lemon lime/;

is ($class->wordlist (@fruits),
	'apple, orange, lemon, and lime',
	'Plain wordlist class method'
);
is ($class->wordlist (@fruits, {final_sep => ''}),
	'apple, orange, lemon and lime',
	'without Oxford comma'
);
is ($class->wordlist (@fruits, {sep => ';'}),
	'apple; orange; lemon; and lime',
	'with semicolon separator'
);
is ($class->wordlist (@fruits, {conj => 'or'}),
	'apple, orange, lemon, or lime',
	'with specified conjunction'
);
