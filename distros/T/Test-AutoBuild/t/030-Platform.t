# -*- perl -*-

use Test::More tests => 15;
use warnings;
use strict;
use Log::Log4perl;

use File::Spec::Functions qw(catfile rootdir);

use POSIX qw(uname);

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Platform") or die;
}

TEST_HOST: {
    my $host = Test::AutoBuild::Platform->new(name => "host");
    isa_ok($host, "Test::AutoBuild::Platform");
    is($host->name, "host", "name is 'host'");

    SKIP: {
	my $issue = catfile(rootdir, "etc", "issue");
	skip "no $issue file to verify", 1 unless -f $issue;
	open ISSUE, $issue
	    or die "cannot read $issue: $!";
	my $label = <ISSUE>;
	close ISSUE;
	chomp $label;

	is($host->label, $label, "label matches $issue");
    }

    is($host->operating_system, (uname())[0], "os matches uname sysname field");
    is($host->architecture, (uname())[4], "os matches uname machine field");
}


TEST_EXPLICIT: {
    my $host = Test::AutoBuild::Platform->new(name => "chroot-debian",
					      label => "Debian Hurd on IA-64",
					      operating_system => "GNU/Hurd",
					      architecture => "ia64");

    is($host->name, "chroot-debian", "name is 'chroot-debian'");
    is($host->label, "Debian Hurd on IA-64", "label is 'Debian Hurd on IA-64'");
    is($host->operating_system, "GNU/Hurd", "operating_system is GNU/Hurd");
    is($host->architecture, "ia64", "architecture is ia64");
}


TEST_OPTIONS: {
    my $host = Test::AutoBuild::Platform->new(name => "host",
					      options => {
						  compiler => "GCC 3.2.3",
					      });

    is($host->option("compiler"), "GCC 3.2.3", "compiler is GCC 3.2.3");
    is($host->option("linker"), undef, "linker is not set");
    my @opts1 = $host->options;
    is_deeply(\@opts1, ["compiler"], "only one option set");
    $host->option("linker", "GNU LD 2.15");
    is($host->option("linker"), "GNU LD 2.15", "linker is 'GNU LD 2.15");
    my @opts2 = sort { $a cmp $b } $host->options;
    is_deeply(\@opts2, ["compiler", "linker"], "two options set");
}
