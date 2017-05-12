# perl syntax check for all cgi scripts

use strict;
use warnings;
use Test::More;
use Test::Strict;
use File::Find;
use File::Slurp 'slurp';

my @scripts = map { local $_ = $_; "script/$_.cgi" } qw(
    ospfview
);

plan tests => 5 * @scripts;

# loading OSPF::LSDB causes problems on cpantesters.org
# due to modified INC on some platforms
my $errout = `perl -I blib/lib -T -e 'use OSPF::LSDB' 2>&1`;
my $skip_Tc = $? || $errout ? 1 : 0;

foreach my $file (@scripts) {
    SKIP: {
	skip "perl taint mode use OSPF::LSDB", 1 if $skip_Tc;
	print STDERR grep { ! /^$file syntax OK$/ }
	    `perl -I blib/lib -T -c $file 2>&1`;
	cmp_ok($?, '==', 0, "$file syntax")
	    or diag("$file syntax check failed");
    }
    like((slurp($file))[0], qr{^#!/usr/bin/perl -T$}, "$file taint")
	or diag("$file taint check failed");
    strict_ok($file, "$file strict") or diag("$file use strict missing");
    warnings_ok($file, "$file warnings") or diag("$file use warnings missing");
}

my %files = map { $_ => 1 } @scripts;
sub wanted {
    ! /[A-Z]/ && /\.cgi$/ && -f or return;
    ok($files{$File::Find::name}, "$File::Find::name file")
	or diag("Executable file $File::Find::name not in cgi script list");
}
find(\&wanted, "script");
