package Stance::GitHub::Organization;
use strict;
use warnings;

use Stance::GitHub::Repository;

sub new {
	my ($class, $gh, $object) = @_;

	return bless {
		_github => $gh,

		(map { $_ => $object->{$_} } qw[id login description]),
		urls => {
			main => $object->{url},
			(map {
				my $k = $_; $k =~ s/_url$//;
				$k => $object->{$_}
			} grep { m/_url$/ } keys %$object)
		}
	}, $class;
}

sub details {
	my ($self) = @_;
	$self->{_details} ||= $self->{_github}->get($self->{urls}{main});
	return $self->{_details};
}

sub repos {
	my ($self) = @_;
	$self->{_repos} ||= [
		map { Stance::GitHub::Repository->new($self->{_github}, $_) }
		@{ $self->{_github}->get($self->{urls}{repos}) } ];
	return @{ $self->{_repos} };
}

1;
