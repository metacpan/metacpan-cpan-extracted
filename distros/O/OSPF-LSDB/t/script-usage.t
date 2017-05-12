# check usage for all perl scripts

use strict;
use warnings;
use Test::More;
use File::Find;

my @scripts = map { local $_ = $_; "script/$_" } qw(
    ciscoospf2yaml
    gated2yaml
    ospf2dot
    ospfconvert
    ospfd2yaml
    ospfview
);

plan tests => 3 * @scripts;

foreach (@scripts) {
    my $pid = open(my $fh, '-|');
    defined($pid) or die "Fork and open pipe failed: $!";
    if (!$pid) {
	# child
	open(STDERR, '>&', \*STDOUT) or die "Dup stdout to stderr failed: $!";
	$0 = $_;
	@ARGV = '-h';
	do $0;
	die "Do $0 did not exit";
    }
    my $out = eval { local $/; <$fh> };
    close($fh) || !$! or die "Fork and open pipe failed: $!";
    is($?, 2<<8, "$_ exit") or diag("Script $_ exit code is not 2<<8: $?");
    like($out, qr{^Usage: $_ }m, "$_ usage") or diag("No usage: $out");
}

my %files = map { $_ => 1 } @scripts;
sub wanted {
    ! /[A-Z]/ && ! /\.cgi$/ && -f or return;
    ok($files{$File::Find::name}, "$File::Find::name file")
	or diag("Executable file $File::Find::name not in script list");
}
find(\&wanted, "script");
