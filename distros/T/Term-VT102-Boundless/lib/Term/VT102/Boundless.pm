#!/usr/bin/perl

package Term::VT102::Boundless;
use base qw/Term::VT102/;

use strict;
use warnings;

our $VERSION = "0.04";

sub new {
	my ( $class, @args ) = @_;

	my $self = $class->SUPER::new(
		cols => 1,
		rows => 1,
		@args,
	);

	return $self;
}

sub _process_text {
	my ( $self, $text ) = @_;

	return if ($self->{'_xon'} == 0);

	my ( $x, $y ) = @{ $self }{qw(x y)};

	# for is used for aliasing
	for my $row ( $self->{'scrt'}[$y] ) {
		$row = '' unless defined $row;

		if ( length($row) - $x ) {
			$row .= " " x ( $x - length($row) );
		}

		substr ( $row, $x - 1, length $text) = $text;

		my $newcols = length $row;
		$self->{'cols'} = $newcols if $newcols > $self->{'cols'};
	}

	for my $row_attrs ( $self->{'scra'}[$y] ) {
		$row_attrs = '' unless defined $row_attrs;

		if ( ( length($row_attrs) / 2 ) - $x ) {
			$row_attrs .= Term::VT102::DEFAULT_ATTR_PACKED x ( $x - ( length($row_attrs) / 2 ) );
		}

		substr ( $row_attrs, 2 * ($x - 1), 2 * (length $text) ) = $self->{'attr'} x (length $text);
	}

	$self->{'x'} += length $text;

	$self->callback_call('ROWCHANGE', $y, 0);
}

sub _move_down {                         # move cursor down
	my ( $self, $num ) = @_;

	$num = 1 if (not defined $num);
	$num = 1 if ($num < 1);

	$self->{'y'} += $num;
	return if ($self->{'y'} <= $self->{'srb'});

	$self->{'srb'} = $self->{'rows'} = $self->{'y'};
}

sub row_attr {
	my ( $self, $row, @args ) = @_;
	$self->_extend_row($row);
	$self->SUPER::row_attr( $row, @args );
}

sub row_text {
	my ( $self, $row, @args ) = @_;
	$self->_extend_row($row);
	$self->SUPER::row_text( $row, @args );
}

sub _extend_row {
	my ( $self, $row ) = @_;

	# if the screen has grown since a row was processed, fill in the missing bits

	if ( (my $extend = $self->{cols} - length($self->{scrt}[$row]))  > 0 ) {
		$self->{scra}[$row] .= Term::VT102::DEFAULT_ATTR_PACKED x $extend; # FIXME use the last attr in the row instead?
		$self->{scrt}[$row] .= ("\x00" x $extend);
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Term::VT102::Boundless - A L<Term::VT102> that grows automatically to
accomodate whatever you print to it.

=head1 SYNOPSIS

	use Term::VT102::Boundless;

	my $t = Term::VT102::Boundless->new(
		# you can optionally specify minimal dimensions
		cols => 80,
		rows => 24,
	);

	$t->process($_) for @text;

	warn "screen dimensions are " . $t->cols . "x" . $t->rows;

=head1 DESCRIPTION

This is a subclass of L<Term::VT102> that will grow the virtual screen to
accomodate arbitrary width and height of text.

The behavior is more similar to the buffer of a scrolling terminal emulator
than to a real terminal, making it useful for output displays in scrolling
media.

=head1 METHODS

=over 4

=item new

Overrides L<Term::VT102/new>, providing default C<cols> and C<rows> values of
C<1> (instead of C<80> and C<24>).

=back

=head1 SEE ALSO

L<Term::VT102>, L<HTML::FromANSI>, L<Term::ANSIColor>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut

