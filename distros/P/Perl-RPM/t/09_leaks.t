#!/usr/bin/perl
use strict;

BEGIN {
    eval {
        require Devel::Leak;
        require Test::More;
    };
    if ($@) {
        print "1..0 # Skip Devel::Leak and Test::More required\n";
        exit 0;
    }
}

use Test::More tests => 11;

sub test_leak (&$;$) {
	my ($code, $descr, $maxleak) = (@_, 0);
	my $n1 = Devel::Leak::NoteSV(my $handle);
	$code->() for 0..3;
	my $n2 = Devel::Leak::CheckSV($handle);
	cmp_ok($n1 + $maxleak, '>=', $n2, $descr);
}

use RPM::Database;

test1: test_leak { my $db = RPM::Database->new or die }
	"rpmdb_TIEHASH", 1; # XXX

test2: test_leak { my $db = RPM::Database->new(root => "/dev/null") }
	"rpmdb_TIEHASH w/ invalid args";

test3: test_leak { my $db = RPM::Database->new or die;
		for (0..3) { my $hdr = $$db{rpm} or die; } }
	"rpmdb_FETCH";

test4: test_leak { my $db = RPM::Database->new or die;
		for (0..3) { my $hdr = $$db{rpm} or die;
			for (0..3) {
				my $name = $$hdr{NAME} or die; 
				my $summary = $$hdr{SUMMARY} or die; } } }
	"rpmhdr_FETCH";

test5: test_leak { my $db = RPM::Database->new or die;
		for (0..3) { $db->find_by_file("/usr/bin/perl") or die; } }
	"find_by_file";

test6: test_leak { my $db = RPM::Database->new or die;
		for (0..3) {	$db->find_what_provides("/bin/sh") or
				$db->find_what_provides("perl(perl5db.pl)"); } }
	"find_what_provides";

# expensive tests
test7: test_leak { my $db = RPM::Database->new or die;
		for (0..3) {	$db->find_what_requires("/bin/sh") or
				warn "/bin/sh not required?"; } }
	"find_what_requires";

test8: test_leak {  my $db = RPM::Database->new or die;
                    my $hdr = $$db{rpm} or die;
		while (my ($k, $v) = each %$hdr) { die if $k eq $v; } }
	"rpmhdr_NEXTKEY";

test9: test_leak { my $db = RPM::Database->new or die;
		while (my ($k, $v) = each %$db) { die if $k eq $v; } }
	"rpmdb_NEXTKEY";

test10: test_leak { my $hdr = RPM::Header->new or die;
		$$hdr{NAME} = "glibc"; $$hdr{SERIAL} = int 6;
		$$hdr{VERSION} = "2.3.5"; $$hdr{RELEASE} = "alt7"; }
	"rpmhdr_STORE";

use RPM::Header;
use RPM qw(evrcmp);
test11: test_leak { evrcmp("1:1-1", "2:2-2") == -1 or die; } "evrcmp";
