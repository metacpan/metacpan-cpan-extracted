package Statistics::Welford;

=pod

=head1 NAME

Statistics::Welford - Standard statistics using Welford's algorithm

=head1 SYNOPSIS

  my $stat = Statistics::Welford->new;

  while (1) {
	$stat->add(rand);
	...
  }

  print $stat->mean;

=head1 DESCRIPTION

Standard statistics using Welford's algorithm

=head1 METHODS

=cut

use strict;
use warnings;

our $VERSION = '0.02';

=pod

=head2 new

  my $stat = Statistics::Welford->new;

The C<new> constructor lets you create a new B<Statistics::Welford> object.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->{n} = 0;
	return $self;
}

=pod

=head2 add

Add an entry to the statistics base

=cut

sub add {
	my ($self, $x) = @_;

	$self->{n}++;
	if ($self->{n} == 1) {
		$self->{old_m} = $x;
		$self->{new_m} = $x;
		$self->{min} = $x;
		$self->{max} = $x;
		$self->{old_s} = 0.0;
		return $self;
	}
	$self->{new_m} = $self->{old_m} + ($x - $self->{old_m})/$self->{n};
	$self->{new_s} = $self->{old_s} + ($x - $self->{old_m})*($x - $self->{new_m});
	$self->{min} = $x if $x < $self->{min};
	$self->{max} = $x if $x > $self->{max};

	# set up for next iteration
	$self->{old_m} = $self->{new_m}; 
	$self->{old_s} = $self->{new_s};
	return $self;
}

=head2 n

Returns the number of entries to the statistics base

=cut

sub n {
	my $self = shift;
	return $self->{n};
}

=head2 min

Returns the minimum number in the statistics base

=cut

sub min {
	my $self = shift;
	return $self->{min};
}

=head2 max

Returns the maximum number in the statistics base

=cut

sub max {
	my $self = shift;
	return $self->{max};
}

=head2 mean

Returns the mean value

=cut

sub mean {
	my $self = shift;
	return $self->{n} > 0 ? $self->{new_m} : 0.0;
}

=head2 variance

Returns the variance value

=cut

sub variance {
	my $self = shift;
	return $self->{n} > 1 ? $self->{new_s}/($self->{n} - 1) : 0.0;
}

=head2 standard_deviation

Returns the standard deviation value

=cut

sub standard_deviation {
	my $self = shift;
	return sqrt( $self->variance );
}

1;

=pod

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2010, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
