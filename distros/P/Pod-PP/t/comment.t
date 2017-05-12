#!./perl

#
# $Id: comment.t,v 0.1 2001/04/25 10:41:49 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: comment.t,v $
# Revision 0.1  2001/04/25 10:41:49  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..7\n";

require 't/code.pl';
sub ok;

sub cleanup {
	unlink 't/out';
}
cleanup;

system "podpp -o t/out t/doc/comments";
ok 1, $? == 0;
ok 2, -e "t/out";
ok 3, !-s("t/out");

system "podpp -o t/out t/doc/bad_include >/dev/null 2>&1";
ok 4, $? == 0;
ok 5, contains("t/out", '^=for pp comment');
ok 6, contains("t/out", 'Following "=pp" directive failed:');
ok 7, contains("t/out", '^\t=pp include "');

cleanup;

