#########
# Author:        rmp
# Maintainer:    $Author: ajb $
# Created:       2007-10
# Last Modified: $Date: 2009-07-07 15:36:09 +0100 (Tue, 07 Jul 2009) $
# Id:            $Id: 00-pod.t 5780 2009-07-07 14:36:09Z ajb $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-pipeline/trunk/t/00-pod.t $
#
use strict;
use warnings;
use Test::More;

our $VERSION = do { my @r = (q$LastChangedRevision: 5780 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

if (!$ENV{TEST_AUTHOR}) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval "use Test::Pod 1.00"; ## no critic
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
