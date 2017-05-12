#!./perl

#
# $Id: pass_through.t,v 0.1 2001/04/25 10:41:50 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: pass_through.t,v $
# Revision 0.1  2001/04/25 10:41:50  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

print "1..8\n";

require 't/code.pl';
sub ok;

sub cleanup {
	unlink 't/out';
}
cleanup;

system "podpp -o t/out t/doc/mixing";
ok 1, $? == 0;
ok 2, -s("t/out");

ok 3, !contains("t/out", '^=.*\bpp\b');
ok 4, contains("t/out", '^=begin something');
ok 5, contains("t/out", '^=end something');
ok 6, contains("t/out", '^This line must pass through');
ok 7, contains("t/out", '^This line is shown');
ok 8, contains("t/out", '^=head1 TITLE');

cleanup;

