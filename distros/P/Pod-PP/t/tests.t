#!./perl

#
# $Id: tests.t,v 0.1 2001/04/25 10:41:50 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: tests.t,v $
# Revision 0.1  2001/04/25 10:41:50  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..6\n";

require 't/code.pl';
sub ok;

sub cleanup {
	unlink 't/out';
}
cleanup;

system "podpp -o t/out t/doc/tests";
ok 1, $? == 0;
ok 2, contains("t/out", 'DIR defined');
ok 3, contains("t/out", 'Fermat OK for dim=2');
ok 4, contains("t/out", 'X = 3');
ok 5, contains("t/out", 'ifndef works');
ok 6, !contains("t/out", '^Bug');

cleanup;

