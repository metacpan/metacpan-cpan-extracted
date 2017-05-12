#########
# Author:        rmp
# Last Modified: $Date: 2008-07-21 12:12:22 +0100 (Mon, 21 Jul 2008) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 207 2008-07-21 11:12:22Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 207 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
