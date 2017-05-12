# run perl script ospf2dot

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 4 + 2 * 5;

my %tmpargs = (
    SUFFIX => ".dot",
    TEMPLATE => "ospfview-script-ospf2dot-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $tmp = File::Temp->new(%tmpargs);

$0 = "script/ospf2dot";
@ARGV = ('-cBSE', "example/all.yaml", $tmp->filename);
my $done = do $0;
ok(!$@, "$0 parse") or diag("Parse $0 failed: $@");
ok(defined $done, "$0 do") or diag("Do $0 failed: $!");
ok($done, "$0 run") or diag("Run $0 failed");

is(slurp($tmp), slurp("example/all.dot"), "$0 output") or do {
    diag("example/all.yaml not converted to example/all.dot");
    system('diff', '-up', "example/all.dot", $tmp->filename);
};

foreach my $opt (qw(b e p s w)) {
    my $options = '-'.lc($opt).uc($opt);
    my $pid = open(my $fh, '-|');
    defined($pid) or die "Fork and open pipe failed: $!";
    if (!$pid) {
	# child
	open(STDERR, '>&', \*STDOUT) or die "Dup stdout to stderr failed: $!";
	@ARGV = ($options, "/dev/null");
	do $0;
	die "Do $0 did not exit";
    }
    my $out = eval { local $/; <$fh> };
    close($fh) || !$! or die "Fork and open pipe failed: $!";
    is($?, 2<<8, "$0 option $opt")
	or diag("Options $options may not be used together");
    like($out, qr{^Error: Options -$opt }m, "$0 usage $opt")
	or diag("No error: $out");
}
