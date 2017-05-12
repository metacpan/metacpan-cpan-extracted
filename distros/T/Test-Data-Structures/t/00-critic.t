#########
# Author:        rmp
# Last Modified: $Date: 2009-07-07 15:36:09 +0100 (Tue, 07 Jul 2009) $ $Author: ajb $
# Id:            $Id: 00-critic.t 5780 2009-07-07 14:36:09Z ajb $
# Source:        $Source: /cvsroot/Bio-DasLite/Bio-DasLite/t/00-critic.t,v $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-pipeline/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$LastChangedRevision: 5780 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

if (!$ENV{TEST_AUTHOR}) {
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
			     -exclude => [qw{
			       tidy
			       ValuesAndExpressions::ProhibitImplicitNewlines
			       Miscellanea::RequireRcsKeywords
			       Documentation::RequirePodAtEnd
			     }],
			     -profile => 't/perlcriticrc',
			    );
  all_critic_ok();
}

1;
