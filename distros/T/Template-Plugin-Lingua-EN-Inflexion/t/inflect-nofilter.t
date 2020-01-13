#
#===============================================================================
#
#         FILE: inflect-nofilter.t
#
#  DESCRIPTION: Check returns only - no template, no filter
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 15/08/19 12:07:13
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 13;
use Template::Plugin::Lingua::EN::Inflexion;

my $inflect = \&Template::Plugin::Lingua::EN::Inflexion::inflect;

is ($inflect->("<#n:0> <N:formulas>"), 'no formulas', 'Keep plural formulas');
is ($inflect->("<#n:0> <N:formulae>"), 'no formulae', 'Keep plural formulae');
is ($inflect->("<#n:0> <N:formula>"),  'no formulas', 'Modern plural formulas');
is ($inflect->("<#n:0> <Nc:formula>"), 'no formulae', 'Classical plural formulae');

is ($inflect->("<#a:1> <N:ant>"), 'an ant', 'Indef art for leading vowel');
is ($inflect->("<#a:1> <N:bat>"), 'a bat',  'Indef art for leading consonant');

is ($inflect->("<#o:1>"),  '1st',   'Numeric ordinal');
is ($inflect->("<#ow:1>"), 'first', 'Lexical ordinal');

is ($inflect->("<#d:2><V:is>"),  'are',   'Irregular verb plural');
is ($inflect->("<#d:2><A:my>"),  'our',   'Irregular adjective plural');

for my $i (0..2) {
	is ($inflect->("<#d:$i><A:red>"), 'red', "Regular adjective number ($i)");
}
