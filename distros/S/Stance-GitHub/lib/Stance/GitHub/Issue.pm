package Stance::GitHub::Issue;
use strict;
use warnings;

sub new {
	my ($class, $gh, $object) = @_;

	return bless {
		_github => $gh,

		(map { $_ => $object->{$_} } grep { !m/_url$/ } keys %$object),
		urls => {
			main => $object->{url},
			(map {
				my $k = $_; $k =~ s/_url$//;
				$k => $object->{$_}
			} grep { m/_url$/ } keys %$object)
		}
	}, $class;
}

1;
