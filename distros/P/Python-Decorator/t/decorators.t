use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {
    use check_requirements;
    plan tests => 5;
};

# test files to filter
my @TESTS = (
    'test_one_decorator.pl'             => 'test_one_decorator.txt',
    'test_one_decorator_with_args.pl'   => 'test_one_decorator_with_args.txt',
    'test_many_decorators.pl'           => 'test_many_decorators.txt',
    'test_many_decorators_with_args.pl' => 'test_many_decorators_with_args.txt',
    'test_comments.pl'                  => 'test_comments.txt',
    );

# where are we running from?
my $path = "";
if (-e "./decorators.t") {
    $path = "./files";
} elsif (-e "./t/decorators.t") {
    $path = "./t/files";
}

while (@TESTS) {
    my $file = $path."/".(shift @TESTS);
    my $want = $path."/".(shift @TESTS);

    # we do the diff between files manually, in order to
    # see exactly where they differ

    my $diff = 0;
    my $line = 0;

    open(RUN,"perl $file |") or die "ERROR: failed to run perl $file: $!";
    open(WANT,$want) or die "ERROR: failed to read file $want: $!";

    while (1) {
	my $got = <RUN>;
	my $expect = <WANT>;
	$line++;

	if (!defined $got && !defined $expect) {
	    last;

	} elsif (!defined $got || !defined $expect) {
	    $diff = 1;
	    print "# differ at line $line:\n";
	    print "# [".((defined $got)?$got:"*undef*")."]\n";
	    print "# [".((defined $expect)?$expect:"*undef*")."]\n";
	    last;

	} else {
	    # PPI does some magic with tabs, so we want them gone
	    $got =~ s/^(\s+)//gm;
	    $expect =~ s/^(\s+)//gm;

	    if ($got ne $expect) {
		$diff = 1;
		chomp $got; chomp $expect;
		print "# differ at line $line:\n";
		print "# [$got]\n";
		print "# [$expect]\n";
		last;
	    }
	}
    }

    close(RUN);
    close(WANT);

    ok($diff == 0,"filtered $file");
}

