use strict;
use warnings;
use Perlmazing;

sub main {
	my $offset = 0;
	(@_) = ($_) if not @_ and defined $_;
	if (not defined wantarray) {
		foreach my $i (@_) {
			no warnings;
			defined($i) ? print "$i\n" : print "\n";
		}
		print "\n" if not @_;
	} elsif (defined wantarray and not wantarray) {
		my $res;
		foreach my $i (@_) {
			$res .= defined($i) ? "$i\n" : "\n";
		}
		return "\n" if not @_;
		return $res;
	} elsif (wantarray) {
		my @res;
		foreach my $i (@_) {
			push @res, defined($i) ? "$i\n" : "\n";
		}
		return "\n" if not @_;
		return @res;
	}
}

1;