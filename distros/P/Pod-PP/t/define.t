#!./perl

#
# $Id: define.t,v 0.1 2001/04/25 10:41:49 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: define.t,v $
# Revision 0.1  2001/04/25 10:41:49  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..2\n";

require 't/code.pl';
sub ok;

sub cleanup {
	unlink 't/out';
}
cleanup;

system "podpp -o t/out -It/doc/h t/doc/defines";
ok 1, $? == 0;
ok 2, contains("t/out", 'This is /var/tmp and this is /other/dir.$');

cleanup;

