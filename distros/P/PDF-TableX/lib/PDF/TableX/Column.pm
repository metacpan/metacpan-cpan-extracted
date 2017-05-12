package PDF::TableX::Column;

use Moose;
use MooseX::Types;

use PDF::TableX::Types qw/StyleDefinition/;
use PDF::TableX::Cell;

with 'PDF::TableX::Stylable';

has rows  => (is => 'ro', isa => 'Int', default => 0);
has width => (is => 'rw', isa => 'Num');

use overload '@{}' => sub { return $_[0]->{_children} }, fallback => 1;

around 'width' => sub {
	my $orig = shift;
	my $self = shift;
	return $self->$orig() unless @_;
	for (@{ $self->{_children} }) { $_->width(@_) };
	$self->$orig(@_);
	return $self;
};

sub add_cell {
	my ($self, $cell) = @_;
	push @{$self->{_children}}, $cell;
}

sub get_min_width {
	my ($self) = @_;
	my $width = 0;
	for my $cell_min_width ( map {$_->min_width} @{$self->{_children}} ) {
		$width = $cell_min_width if ($cell_min_width > $width);
	}
	return $width;
}

sub get_reg_width {
	my ($self) = @_;
	my $width = 0;
	for my $cell_reg_width ( map {$_->reg_width} @{$self->{_children}} ) {
		$width = $cell_reg_width if ($cell_reg_width > $width);
	}
	return $width;
}

1;

=head1 NAME

PDF::TableX::Column

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

=head1 METHODS

=head2 add_cell

 TODO

=head2 get_min_width

 TODO

=head2 get_reg_width

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