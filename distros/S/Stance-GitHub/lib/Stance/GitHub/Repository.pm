package Stance::GitHub::Repository;
use strict;
use warnings;

use Stance::GitHub::Issue;

sub new {
	my ($class, $gh, $object) = @_;

	return bless {
		_github => $gh,

		(map { $_ => $object->{$_} } grep { !m/^has/ && !m/_url$/ } keys %$object),
		has => {
			(map {
				my $k = $_; $k =~ s/^has_//;
				$k => !!$object->{$_}
			} grep { m/^has_/ } keys %$object)
		},
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

sub issues {
	my ($self) = @_;
	$self->{_issues} ||= [
		return map { Stance::GitHub::Issue->new($self->{_github}, $_) }
		@{ $self->{_github}->get($self->{urls}{issues}) } ];
	return @{ $self->{_issues} };
}

1;
