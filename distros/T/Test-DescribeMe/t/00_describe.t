#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Settings qw(:all);

use Config;
use File::Temp qw(tempfile);

# Find perl binary
my $perlbin;
eval "require Probe::Perl";
unless ($@) {
        $perlbin = Probe::Perl->find_perl_interpreter();
}
$perlbin ||= $Config{perlpath};

# Make sure we have sane settings
disable_smoke;
disable_non_interactive;
disable_extended;
disable_author;
disable_release;

# Test each kind
for my $k (qw(smoke extended author release)) {
	my $output = _run(<<EOF);
use Test::DescribeMe qw($k);
use Test::More;

ok(1, "Ran a test dude");

done_testing;
EOF

	like($output, qr/Skip.* Not running $k tests/i, "Skipping $k tests");

	my $sub = "enable_$k";
	{ no strict 'refs'; $sub->(); } # I'm sorry... -- alh

	$output = _run(<<EOF);
use Test::DescribeMe qw($k);
use Test::More;

ok(1, "Ran a test dude");

done_testing;
EOF

	like($output, qr/Ran a test dude/i, "Test ran with want_$k");
}

# Try 'interactive' as well - it's backwards
my $output = _run(<<EOF);
use Test::DescribeMe qw(interactive);
use Test::More;

ok(1, "Ran a test dude");

done_testing;

EOF

like($output, qr/Ran a test dude/i, "Test ran with want_interactive");

my $sub = "enable_non_interactive";
{ no strict 'refs'; $sub->(); } # I'm sorry... -- alh

$output = _run(<<EOF);
use Test::DescribeMe qw(interactive);
use Test::More;

ok(1, "Ran a test dude");

done_testing;

EOF

like($output, qr/Skip.* Not running interactive tests/i, "Skipping interactive tests");

# Explicit tests don't get stomped on
$output = _run(<<EOF);
use Test::DescribeMe qw(interactive);
use Test::More tests => 1;

ok(1, "Ran a test dude");

done_testing;

EOF

unlike($output, qr/twice/, "No error about two plans");

# But do if we're silly
$output = _run(<<EOF);
use Test::More tests => 1;
use Test::DescribeMe qw(interactive);

ok(1, "Ran a test dude");

done_testing;

EOF

like($output, qr/twice/, "Got an error about two plans");

# Done
	
sub _run {
	my ($program) = @_;

	my ($fh, $name) = tempfile;

	print $fh $program;

	close($fh);

	my $output = `$perlbin $name 2>&1`;

	close($fh);

	unlink($name);

	return $output;
}

done_testing;
