# test program for Sys::Output
#
#    Copyright (C) 1995  Alan K. Stebbens <aks@hub.ucsb.edu>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# $Id: test.pl,v 1.2 1998/01/19 03:57:36 aks Exp $

use Sys::OutPut;

$testout  = 'test.out';		# where this output goes
$testref  = "$testout.ref";
$testdiff = "$testout.diff";

unlink $testout;

open(savSTDOUT, ">&STDOUT");
open(savSTDERR, ">&STDERR");

open(STDOUT,">test.stdout"); open(STDERR,">test.stderr");
select(STDOUT);

&the_test;			# run the test

close STDOUT; close STDERR;

# Copy stdout & stderr to the test.out file
open(TESTOUT,">$testout");
select(TESTOUT);
print "*** STDOUT ***\n";
open(OUT,"<test.stdout"); while (<OUT>) { print; } close OUT;
print "*** STDERR ***\n";
open(ERR,"<test.stderr"); while (<ERR>) { print; } close ERR;
close TESTOUT;
unlink ('test.stdout', 'test.stderr');

open(STDOUT, ">&savSTDOUT");
open(STDERR, ">&savSTDERR");
select(STDOUT); $|=1;

if (! -f $testref) {			# any existing reference?
    system("cp $testout $testref");	# no, copy
}

system("diff $testref $testout >$testdiff");

if ($?>>8) {
    print "Uh-oh! There are differences; see \"$testdiff\".\n";
} else {
    print "Yea! No differences.\n";
    unlink $testdiff;
}

exit;

sub the_test {

    out "(out) This is a test -- there should be a newline on this text.";

    put "(put) This is another test -- ";

    put "(put) this line should continue the previous.";

    out;	# force a newline

    out "(out)This should start and end a new line";

    err "(err)Output should go to stderr";

    out "(out)This line should go to stdout";

    err "(err)This line is back in stderr";

    talk "(talk)This line should print in stderr";

    $Sys::OutPut::quiet = 1;

    talk "(talk)This line should not print!";

    $Sys::OutPut::quiet = '';

    talk "(talk)This line should appear";

    (debug "(debug)This should not print") or
	talk  "(talk)But this should print when debug returns nil";

    $Sys::OutPut::debug = 1;

    (debug "(debug)This is a line of debugging output") and
	err "(err)This line should be in stderr with it.";

    (debug "(debug)This is another line of debugging output") or
	err "(err)This line should not appear!";

}
