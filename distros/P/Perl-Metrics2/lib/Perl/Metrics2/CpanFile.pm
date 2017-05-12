package Perl::Metrics2::CpanFile;

use strict;
use Perl::Metrics2 ();

our $VERSION = '0.06';

sub release_index {
	my $dbh = Perl::Metrics2->dbh or return;
	my $sth = $dbh->prepare('SELECT DISTINCT release FROM cpan_file', {}) or return;
	$sth->execute or return;
	my %hash  = ();
	my $value = undef;
	$sth->bind_col(1, \$value) or return;
	while ( $sth->fetch ) {
		my $one = substr($_, 0, 1);
		my $two = substr($_, 0, 2);
		$hash{"$one/$two/$_"} = 1;
	}
	return \%hash;
}

1;
