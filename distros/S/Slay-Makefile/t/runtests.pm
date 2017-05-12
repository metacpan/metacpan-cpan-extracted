
use strict;
use warnings;

use File::Path qw(rmtree);
use File::Copy::Recursive qw(dircopy);

use Test::More;

use FindBin;

use lib "$FindBin::RealBin/../blib/lib";
use Slay::Makefile;

BEGIN {
    eval "use Devel::Cover qw(-db $FindBin::RealBin/cover_db -silent 1
                              -summary 0 +ignore .* +select Makefile.pm)"
	if $ENV{COVER};
}

sub do_tests {
    my $base = $FindBin::RealBin;
    my ($myname) =  $FindBin::RealScript =~ /(.*)\.t$/;
    chdir $base;
    die "Error: No init directory for this test\n" unless -d "$myname.init";

    # First create the subdirectory for doing testing
    rmtree "$myname.dir" if -d "$myname.dir";
    dircopy "$myname.init", "$myname.dir";

    chdir "$myname.dir";

    # Check to see if we need to skip all tests
    if (-f "skip.pl") {
	chomp (my $error = `$^X -I $base/blib/lib skip.pl 2>&1`);
	plan(skip_all => "$error") if $?;
    }

    my %options;
    my $sm = Slay::Makefile->new();
    $sm->parse("../Common.smak");
    $sm->maker->check_targets('test');

    # Get list of targets
    my ($rule, $deps, $matches) = $sm->maker->get_rule_info('test');
    my @tests = @ARGV ? @ARGV : defined $rule && $deps ? @$deps : () ;
    plan tests => 0+@tests;
    foreach my $test (@tests) {
	$sm->make($test);
	my $ok = -r $test ? `cat $test` : "Failed to build $test";
	is ($ok, '', $test);
    }
}

1;
