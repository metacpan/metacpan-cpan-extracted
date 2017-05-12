package PDF::TableX::Cell;

use Moose;
use MooseX::Types;
use PDF::API2;

with 'PDF::TableX::Drawable';
with 'PDF::TableX::Stylable';

has width     => (is => 'rw', isa => 'Num');
has min_width => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_min_width');
has reg_width => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_reg_width');
has height    => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_height' );
has content   => (is => 'rw', isa => 'Str', default=> '', trigger => sub { $_[0]->{_overflow} = $_[0]->content; });

has _overflow        => (is => 'ro', isa => 'Str', init_arg => undef, default => '');
has _pdf_api_content => (is => 'ro', isa => class_type('PDF::API2::Page'), lazy => 1, builder => '_get_content');
has _parent          => (is => 'ro', isa => 'Object');
has _row_idx         => (is => 'ro', isa => 'Int', default => 0);
has _col_idx         => (is => 'ro', isa => 'Int', default => 0);

around 'content' => sub {
	my $orig = shift;
	my $self = shift;
	return $self->$orig() unless @_;
	$self->$orig(@_);
	return $self;
};

sub _get_content { return PDF::API2->new()->page; }

sub _get_min_width {
	my ($self) = @_;
	my $txt = $self->_pdf_api_content->text();
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	my $min_width = 0;
	for (split(/\s/, $self->content)) {
		my $word_width = $txt->advancewidth($_);
		$min_width = ($word_width > $min_width) ? $word_width : $min_width;
	}
	return $min_width + $self->padding->[1] + $self->padding->[3];
}

sub _get_reg_width {
	my ($self) = @_;
	my $txt = $self->_pdf_api_content->text();
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	my $reg_width = 0;
	for (split("\n", $self->content)) {
		my $line_width = $txt->advancewidth($_);
		$reg_width = ($line_width > $reg_width) ? $line_width : $reg_width;
	}
	return $reg_width + $self->padding->[1] + $self->padding->[3];
}

sub _get_height {
	my ($self) = @_;
	my $height = $self->padding->[0] + $self->padding->[2];
	$height   += scalar(split("\n", $self->content)) * $self->font_size;
	return $height;
}

sub draw_content {
	my ($self, $x, $y, $gfx, $txt) = @_;
	$y -= $self->padding->[0] + $self->font_size;
	$x += $self->padding->[3]
		+ ($self->text_align eq 'right'  ? $self->get_text_width   : 0)
		+ ($self->text_align eq 'center' ? $self->get_text_width/2 : 0)
	;
	my $width = 0;
	$txt->save;
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	$txt->lead( $self->font_size );
	$txt->fillcolor( $self->font_color );
	$txt->translate($x, $y);
	my $overflow = '';
	for my $p ( split ( "\n", $self->{_overflow} ) ) {
		if ($overflow) {
			$overflow .= "\n" . $p;
		} else {
			$overflow = $txt->paragraph($p, $self->get_text_width, ($y-$self->margin->[2]-$self->padding->[2]+$self->font_size), -spillover => 0, -align => $self->text_align);
		}
	}
	$self->{_overflow} = $overflow;
	$self->height( $y - [ $txt->textpos() ]->[1] + $self->padding->[0] + $self->padding->[2]);
	$txt->restore;
	return ($self->get_text_width, $self->height, length($overflow));
}

sub reset_content {
	my ($self) = @_;
	$self->{_overflow} = $self->content;
	return $self;
}

sub get_text_width {
	my ($self) = @_;
	return $self->width - $self->padding->[1] - $self->padding->[3];
}

sub draw_borders {
	my ($self, $x, $y, $gfx, $txt) = @_;
	if ($self->border_width->[0]) {$self->_draw_top_border($x, $y, $gfx)}
	if ($self->border_width->[1]) {$self->_draw_right_border($x, $y, $gfx)}
	if ($self->border_width->[2]) {$self->_draw_bottom_border($x, $y, $gfx)}
	if ($self->border_width->[3]) {$self->_draw_left_border($x, $y, $gfx)}
}

sub _draw_top_border {
	my ($self, $x, $y, $gfx) = @_;
	$y = ($self->{_row_idx} == 0) ? $y-$self->border_width->[0]/2 : $y;
	$gfx->move($x, $y);
	$gfx->linewidth($self->border_width->[0]);
	$gfx->strokecolor($self->border_color->[0]);
	$gfx->hline($x+$self->width);
	$gfx->stroke();
}

sub _draw_right_border {
	my ($self, $x, $y, $gfx) = @_;
	$x = ($self->{_parent}->is_last_in_row($self->{_col_idx})) ? $x-$self->border_width->[1]/2 : $x;
	$gfx->move($x+$self->width, $y);
	$gfx->linewidth($self->border_width->[1]);
	$gfx->strokecolor($self->border_color->[1]);
	$gfx->vline($y-$self->height);
	$gfx->stroke();
}

sub _draw_bottom_border {
	my ($self, $x, $y, $gfx) = @_;
	$y = ($self->{_parent}->is_last_in_col($self->{_row_idx})) ? $y+$self->border_width->[2]/2 : $y;
	$gfx->move($x, $y-$self->height);
	$gfx->linewidth($self->border_width->[2]);
	$gfx->strokecolor($self->border_color->[2]);
	$gfx->hline($x+$self->width);
	$gfx->stroke();
}

sub _draw_left_border {
	my ($self, $x, $y, $gfx) = @_;
	$x = ($self->{_col_idx} == 0) ? $x+$self->border_width->[3]/2 : $x;
	$gfx->move($x, $y);
	$gfx->linewidth($self->border_width->[3]);
	$gfx->strokecolor($self->border_color->[3]);
	$gfx->vline($y-$self->height);
	$gfx->stroke();
}

sub draw_background {
	my ($self, $x, $y, $gfx, $txt) = @_;
	if ( $self->background_color ) {
		$gfx->linewidth(0);
		$gfx->fillcolor($self->background_color);
		$gfx->rect($x, $y-$self->height, $self->width, $self->height);
		$gfx->fill();
	}
}

1;

=head1 NAME

PDF::TableX::Cell

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

=head1 METHODS

=head2 background_color

 TODO

=head2 border_color

 TODO

=head2 border_style

 TODO

=head2 border_width

 TODO

=head2 content

 TODO

=head2 draw_background

 TODO

=head2 draw_borders

 TODO

=head2 draw_content

 TODO

=head2 font

 TODO

=head2 font_color

 TODO

=head2 font_size

 TODO

=head2 get_text_width

 TODO

=head2 height

 TODO

=head2 margin

 TODO

=head2 meta

 TODO

=head2 min_width

 TODO

=head2 padding

 TODO

=head2 reg_width

 TODO

=head2 reset_content

 TODO

=head2 text_align

 TODO

=head2 width

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
