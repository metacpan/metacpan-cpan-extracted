
package OOPS::TestSetup;

use strict;
use warnings;

my %dbi = (
	pg	=> 'PostgreSQL',
	mysql	=> 'mysql',
	sqlite	=> 'SQLite',
	sqlite2	=> 'SQLite2',
	sqlite3	=> 'SQLite3',
);

sub import
{
	my ($pkg, @args) = @_;

	my $dbicheck = 0;
	my @supported;

	for my $a (@args) {
		if ($a eq ':filter') {
			$OOPS::SelfFilter::defeat = 1
				unless defined $OOPS::SelfFilter::defeat;
			$OOPS::OOPS1001::SelfFilter::defeat = 1
				unless defined $OOPS::OOPS1001::SelfFilter::defeat;
			$OOPS::OOPS1003::SelfFilter::defeat = 1
				unless defined $OOPS::OOPS1003::SelfFilter::defeat;
			$OOPS::OOPS1004::SelfFilter::defeat = 1
				unless defined $OOPS::OOPS1004::SelfFilter::defeat;
		} elsif ($a eq ':inactivity') {
			$Test::MultiFork::inactivity = 60;
		} elsif ($a eq ':slow') {
			if ($ENV{HARNESS_ACTIVE} && ! $ENV{OOPSTEST_SLOW}) {
				print "1..0 # skip run this by hand or set \$ENV{OOPSTEST_SLOW}\n";
				exit;
			}
		} elsif ($a =~ /^:(-)?(.+)/) {
			my $dbd = $2;
			if ($dbi{$dbd}) {
				if ($1) {
					if ($ENV{OOPSTEST_DSN} && $ENV{OOPSTEST_DSN} =~ /^dbi:$dbd\b/i) {
						print "1..0 # skip this test not for $dbi{$dbd}\n";
						exit;
					}
				} else {
					$dbicheck = $dbd if ($ENV{OOPSTEST_DSN} && $ENV{OOPSTEST_DSN} =~ /^dbi:$dbd\b/i);
					push(@supported, $dbi{$dbd});
				}
			} else {
				die "Bad import spec: $a";
			}
		} else {
			unless ( eval " require $a " ) {
				print "1..0 # skip this test requires the $a module\n";
				exit;
			}
		}
	}

	if (@supported && ! $dbicheck) {
		print "1..0 # skip test requires " . join(" or ", @supported) . "\n";
		exit;
	}
}

1;
