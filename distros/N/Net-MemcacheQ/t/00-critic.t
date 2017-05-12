#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 1 $ =~ /\d+/smxg); sprintf '%d.'.'%03d' x $#r, @r };

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 1,
			     -exclude => [qw(CodeLayout::RequireTidyCode
					     PodSpelling
 					     ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok();
}

1;
