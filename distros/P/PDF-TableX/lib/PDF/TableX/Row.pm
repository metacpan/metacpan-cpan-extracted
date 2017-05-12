package PDF::TableX::Row;

use Moose;
use MooseX::Types;

with 'PDF::TableX::Drawable';
with 'PDF::TableX::Stylable';

use PDF::TableX::Cell;

has cols    => (is => 'ro', isa => 'Int', default => 0);
has width   => (is => 'rw', isa => 'Num');
has height  => (is => 'rw', isa => 'Num');

has _row_idx    => (is => 'ro', isa => 'Int', default => 0);
has _parent     => (is => 'ro', isa => 'Object');

use overload '@{}' => sub { return $_[0]->{_children} }, fallback => 1;

around 'height' => sub {
	my $orig = shift;
	my $self = shift;
	return $self->$orig() unless @_;
	for (@{ $self->{_children} }) { $_->height(@_) };
	$self->$orig(@_);
	return $self;
};


sub BUILD {
	my ($self) = @_;
	$self->_create_children;
}

sub _create_children {
	my ($self) = @_;
	for (0..$self->cols-1) {
		$self->add_cell( PDF::TableX::Cell->new(
			width => ($self->width/$self->cols),
			_row_idx => $self->{_row_idx},
			_col_idx => $_,
			_parent  => $self,
			$self->properties,
		));
	}
}

sub add_cell {
	my ($self, $cell) = @_;
	push @{$self->{_children}}, $cell;
}

sub properties {
	my ($self, @attrs) = @_;
	@attrs = scalar(@attrs) ? @attrs : $self->attributes;
	return ( map { $_ => $self->$_ } @attrs );
}

sub draw_content    {
	my ($self, $x, $y, $gfx, $txt) = @_;
	my $height   = 0;
	my $overflow = 0;
	for (@{$self->{_children}}) {
		my ($w, $h, $o) = $_->draw_content( $x, $y, $gfx, $txt );
		$height = ($height > $h) ? $height : $h;
		$x += ($w > $_->width ? $w : $_->width);
		$overflow += $o;
	}
	if (! $overflow ) { for (@{$self->{_children}}) { $_->reset_content } }
	return ($height, $overflow);
}

sub draw_borders    {
	my ($self, $x, $y, $gfx, $txt) = @_;
	for (@{$self->{_children}}) {
		$_->draw_borders( $x, $y, $gfx, $txt );
		$x += $_->width;
	}
}

sub draw_background {
	my ($self, $x, $y, $gfx, $txt) = @_;
	for (@{$self->{_children}}) {
		$_->draw_background( $x, $y, $gfx, $txt );
		$x += $_->width;
	}
}

sub is_last_in_row {
	my ($self, $idx) = @_;
	return ($idx == $self->cols-1); #index starts from 0
}

sub is_last_in_col {
	my ($self, $idx) = @_;
	return $self->{_parent}->is_last_in_col($idx);
}

1;

=head1 NAME

PDF::TableX::Row

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

=head1 METHODS

=head2 BUILD

 TODO

=head2 add_cell

 TODO

=head2 draw_background

 TODO

=head2 draw_borders

 TODO

=head2 draw_content

 TODO

=head2 is_last_in_col

 TODO

=head2 is_last_in_row

 TODO

=head2 properties

 TODO

=head1 AUTHOR

Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at: L<https://github.com/grzegorzpapkala/PDF-TableX/issues>

=head1 SUPPORT

PDF::TableX is hosted on GitHub L<https://github.com/grzegorzpapkala/PDF-TableX>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Grzegorz Papkala, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut