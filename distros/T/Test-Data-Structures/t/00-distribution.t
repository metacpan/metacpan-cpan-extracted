#########
# Author:        rmp
# Last Modified: $Date: 2009-07-07 15:36:09 +0100 (Tue, 07 Jul 2009) $ $Author: ajb $
# Id:            $Id: 00-distribution.t 5780 2009-07-07 14:36:09Z ajb $
# Source:        $Source: /cvsroot/Bio-DasLite/Bio-DasLite/t/00-distribution.t,v $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-pipeline/trunk/t/00-distribution.t $
#
package distribution;
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
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
