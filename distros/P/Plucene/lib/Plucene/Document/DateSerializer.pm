package Plucene::Document::DateSerializer;

use strict;
use warnings;

use Time::Piece;
use base 'Exporter';

our @EXPORT = qw(freeze_date);

=head1 NAME

Plucene::Document::DateSerializer - Utility functions for dealing with dates

=head1 SYNOPSIS

	use Plucene::Document::DateSerializer
	my $field = Plucene::Document::Field->Text(
		date => freeze_date(Time::Piece $t)
	);
	$doc->add($field);

=head1 DESCRIPTION

Dates and times in Plucene should be serialized using the C<freeze_date> 
function so that the L<Plucene::Search::DateFilter> can filter on them
during future searches.

=head1 SUBROUTINES

=head2 freeze_date

	my $string = freeze_date(Time::Piece $t)

This routine, exported by default, turns a C<Time::Piece> object into
a string in a format expected by both Plucene and Lucene.

=cut

sub freeze_date { _to_base_36(shift->epoch * 1000); }

sub _to_base_36 {
	my $number = shift;
	my $string = "";
	while ($number) {
		my $quot = $number % 36;
		$string = ($quot < 10 ? $quot : chr($quot + 87)) . $string;
		$number = int($number / 36);
	}
	$string = "0$string" while length($string) < 9;
	$string;
}

sub _from_base_36 {
	my $string   = shift;
	my $exponent = 0;
	my $number;
	for (reverse split //, $string) {
		$number += ($_ =~ /\d/ ? $_ : (ord($_) - 87)) * (36**$exponent++);
	}
	return $number;
}

# Java uses milliseconds, but Perl doesn't have 'em

=head2 thaw_date

	my Time::Piece $t = Plucene::Document::DateSerializer::thaw_date($string)

This routine is not exported, and is not used by the Plucene core. It is
useful for debugging dates, and simply reverses the C<freeze_date> operation.

=cut

sub thaw_date {
	my $self = shift;
	return Time::Piece->new(_from_base_36($self) / 1000);
}

1;
