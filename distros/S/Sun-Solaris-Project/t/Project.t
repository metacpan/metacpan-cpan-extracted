#
# Copyright 2000,2002 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#ident	"@(#)Project.t	1.2	02/01/18 SMI"
#
# test script for Sun::Solaris::Project
#

$^W = 1;
use strict;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

#
# Status reporting utils
#

use vars qw($test);
$test = 1;

sub pass
{
	print("ok $test $@\n");
	$test++;
}

sub fail
{
	print("not ok $test $@\n");
	$test++;
}

sub fatal
{
	print("not ok $test $@\n");
	exit(1);
}

#
# Read in a project file and build into the same data structure that we will
# get if we do the same with the getXXX functions
#

sub read_pfile
{
	my ($fh) = @_;
	my ($line, @a1, @a2);
	while (defined($line = <$fh>)) {
		chomp($line);
		@a2 = split(/:/, $line, 6);
		$a2[2] = '' if (! defined($a2[2]));
		$a2[3] = defined($a2[3]) ? [ split(/,/, $a2[3]) ] : [];
		$a2[4] = defined($a2[4]) ? [ split(/,/, $a2[4]) ] : [];
		$a2[5] = '' if (! defined($a2[5]));
		push(@a1, [ @a2 ]);
	}
	return(\@a1);
}

#
# Compare two arrays of project structures & check for equivalence.
# Converts each into a string using Data::Dumper and then does a string
# comparison.  Dirty but effective :-)
#

sub cmp_recs
{
	my ($a1, $a2) = @_;
	my $s1 = Dumper($a1);
	my $s2 = Dumper($a2);

	# Make sure numbers and quoted numbers compare the same
	$s1 =~ s/'([+-]?[\d.]+)'/$1/g;
	$s2 =~ s/'([+-]?[\d.]+)'/$1/g;

	return($s1 eq $s2);
}

#
# Main body of tests stars here
#

my ($loaded, $line) = (1, 0);
my $fh = do { local *FH; *FH; };

# Check the module loads
BEGIN { $| = 1; print "1..16\n"; }
END   { print "not ok 1\n" unless $loaded; }
use Sun::Solaris::Project qw(:ALL :PRIVATE);
$loaded = 1;
pass();

# Check the constants
my ($n1, $n2, $n3, $s);
open($fh, "</usr/include/project.h") || fatal($!);
while (defined($line = <$fh>)) {
	$n1 = $1 if ($line =~ /#define\s+PROJNAME_MAX\s+(\d+)/);
	$n2 = $1 if ($line =~ /#define\s+PROJECT_BUFSZ\s+(\d+)/);
	$s = $1 if ($line =~ /#define\s+PROJF_PATH\s+"([^"]+)"/);
}
close($fh);
open($fh, "</usr/include/sys/param.h") || fatal($!);
while (defined($line = <$fh>)) {
	$n3 = $1 if ($line =~ /#define\s+MAXUID\s+(\d+)/);
}
close($fh);
if (! defined($s) || ! defined($n1) || ! defined($n2)) {
	fail();
} else {
	if ($n1 == &PROJNAME_MAX && $n2 == PROJECT_BUFSZ &&
	    $n3 == &MAXPROJID && $s eq &PROJF_PATH) {
		pass();
	} else {
		fail();
	}
}

# Make a temporary project file
my ($pf1, $pf2, $pass);
open($fh, "+>/tmp/project.$$") || fatal($!);
print $fh <<EOF;
test1:123:project one:root,bin:adm:attr1=a;attr2=b
user.test2:456:project two:adm,uucp:staff:attr1=p;attr2=q
group.test3:678:project three:root,nobody:root,lp:attr1=y;attr2=z
test4:678:project four:0:0:
test5:678:project five::0:
test6:678::::
EOF
seek($fh, 0, 0);
$pf1 = read_pfile($fh);

# Test projf_read
seek($fh, 0, 0);
$pf2 = projf_read($fh);
close($fh);
cmp_recs($pf1, $pf2) ? pass() : fail();

# Test projf_write
open($fh, ">/tmp/project.${$}_a") || fatal($!);
projf_write($fh, $pf2);
close($fh);
system("cmp -s /tmp/project.$$ /tmp/project.${$}_a") == 0 ? pass() : fail();
unlink("/tmp/project.${$}_a");
	
# Test proj_validate
$pass = 1;
foreach my $p (@$pf1) {
	$pass = 0 if (proj_validate($p))
}
$pass ? pass() : fail();
open($fh, "</etc/project") || fatal($!);
$pf2 = projf_read($fh);
close($fh);
$pass = 1;
foreach my $p (@$pf2) {
	$pass = 0 if (proj_validate($p, { res => 1, dup => 1 }))
}
$pass ? pass() : fail();

# Test getprojid
($s) = `/usr/xpg4/bin/id -p` =~ /projid=(\d+)/;
defined($s) && $s == getprojid() ? pass() : fail();

# Test fgetprojent
$pf2 = [];
open($fh, "</tmp/project.$$") || fatal($!);
while (my @proj = fgetprojent($fh)) {
	push(@$pf2, [ @proj ]);
}
close($fh);
cmp_recs($pf1, $pf2) ? pass() : fail();

# We can't test any further than this if project is a YP map
if (system("ypcat project > /dev/null 2>&1") == 0) {
	fatal("Don't know how to test with yp project map");
}

# Read in the /etc/project file, & build the same datastructure as will be
# returned by getprojent et al.  Poor pickings as by default most of the fields
# are empty
open($fh, "<" . &PROJF_PATH) || fatal($!);
$pf1 = read_pfile($fh);
close($fh);
my %pf_byname = map({ $_->[0] => $_} @$pf1);
my %pf_byid = map({ $_->[1] => $_} @$pf1);
my (%h, @a1, @a2, $k, $v);

# Test getprojent.  Don't assume anything about the order it returns stuff in
%h = %pf_byname;
$pass = 1;
@a2 = ();
while (@a1 = getprojent()) {
	@a2 = @a1 if (! scalar(@a2));
	if (exists($h{$a1[0]})) {
		$pass = 0 if (! cmp_recs(\@a1, $h{$a1[0]}));
		delete($h{$a1[0]});
	} else {
		$pass = 0;
	}
}
$pass && ! %h ? pass() : fail();
@a1 = getprojent();
cmp_recs(\@a1, []) ? pass() : fail();

# Test setprojent/endprojent
endprojent();
@a1 = getprojent();
cmp_recs(\@a1, \@a2) ? pass() : fail();
setprojent();
@a1 = getprojent();
cmp_recs(\@a1, \@a2) ? pass() : fail();
setprojent();

# Test getprojbyname
$pass = 1;
while (($k, $v) = each(%pf_byname)) {
	@a1 = getprojbyname($k);
	$pass = 0 if (! cmp_recs(\@a1, $v));
}
$pass ? pass() : fail();

# Test getprojbyid
$pass = 1;
while (($k, $v) = each(%pf_byid)) {
	@a1 = getprojbyid($k);
	$pass = 0 if (! cmp_recs(\@a1, $v));
}
$pass ? pass() : fail();

# Test getprojidbyname
$pass = 1;
while (($k, $v) = each(%pf_byname)) {
	$pass = 0 if (getprojidbyname($k) != $v->[1]);
}
$pass ? pass() : fail();

# Test getdefaultproj
$s = '/usr/xpg4/bin/id -p ' . getpwuid($>);
($s) = `$s` =~ /projid=\d+\(([^)]+)\)/;
defined($s) && $s eq getdefaultproj(getpwuid($>)) ? pass() : fail();

# Test inproj
$pass = 1;
if (! open($fh, "<" . "/etc/passwd")) {
	fatal($!);
}
close($fh);

# Cleanup
unlink("/tmp/project.$$");
