use strict;
use warnings 'FATAL', 'all';
use Getopt::Long;
use Test::More 'no_plan';

use Parse::CPAN::Packages::Fast;

my $v;
GetOptions("v" => \$v)
    or die "usage: $0 [-v]";

{
    my $p = Parse::CPAN::Packages::Fast->new;
    my @distributions = $p->distributions;
    my $i = 0;
    for my $d (@distributions) {
	my $distname = $d->dist;
	if (!defined $distname) {
	    # May happen, e.g. for "T/TO/TOMC/scripts/CS-Talk/source/dstructs/trees/ValueTree.pm.gz"
	    next;
	}
	if ($v) {
	    my $percent = int(100*$i/@distributions); $i++;
	    print STDERR $percent, "% ", $distname, "\n";
        }
	$p->latest_distribution($d->dist);
    }
}

pass 'Iterated over all distributions';

