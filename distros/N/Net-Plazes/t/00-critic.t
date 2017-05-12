#########
# Author:        rmp
# Last Modified: $Date: 2008-07-21 12:12:22 +0100 (Mon, 21 Jul 2008) $ $Author: zerojinx $
# Id:            $Id: 00-critic.t 207 2008-07-21 11:12:22Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-critic.t,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 207 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

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
			     -exclude => ['tidy','ValuesAndExpressions::ProhibitImplicitNewlines'],
			    );
  all_critic_ok();
}

1;
