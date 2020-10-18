use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Grid;
# ABSTRACT: A view model for grid-based views
$Renard::Curie::Model::View::Grid::VERSION = '0.005';
use Moo;

use Renard::Incunabula::Common::Types qw(InstanceOf ArrayRef);
use Intertangle::API::Gtk3::Types qw(SizeRequest);
use POSIX qw(ceil);
use List::AllUtils qw(part first);
use Glib qw(TRUE FALSE);
use Test::Deep::NoTest;

use MooX::Struct
	GridScheme => [ qw( rows columns pages) ]
;

use Renard::Curie::Model::View;
use Glib::Object::Subclass
	'Glib::Object',
	signals => {
		'view-changed' => {},
		'scroll-to-page' => {
			param_types => [
				'Glib::Scalar', # PageNumber
			]
		}
	},
	;
extends 'Renard::Curie::Model::View';

use Renard::Curie::Model::View::Grid::Subview;

classmethod FOREIGNBUILDARGS(@) {
	return ();
}

has view_options => (
	is => 'ro',
	required => 1,
	predicate => 1, # has_view_options
	isa => InstanceOf['Renard::Curie::Model::ViewOptions'],
);

method zoom_level() {
	$self->view_options->zoom_options->zoom_level;
}

has _grid_schemes => (
	is => 'lazy', # _build__grid_schemes
	isa => ArrayRef, # ArrayRef[GridScheme]
);

method _current_subview() {
	$self->_subviews->[ $self->_subview_idx ];
}

method _build__grid_schemes() {
	my $go_r = $self->view_options->grid_options->rows;
	my $go_c = $self->view_options->grid_options->columns;
	my @page_numbers = ( $self->document->first_page_number .. $self->document->last_page_number);

	my ($g_r, $g_c);
	if( defined $go_r && defined $go_c ) {
		($g_r, $g_c) = ($go_r, $go_c);
	} elsif( defined $go_r && ! defined $go_c ) {
		$g_r = $go_r;
		$g_c = ceil($self->document->number_of_pages / $go_r);
	} elsif( ! defined $go_r && defined $go_c ) {
		$g_r = ceil($self->document->number_of_pages / $go_c);
		$g_c = $go_c;
	} else {
		Renard::Incunabula::Common::Error::Programmer::Logic->new(
			msg => 'GridOption improperly constructed: both row and columns undef',
		);
	}

	my $num_pages_per_view = $g_r * $g_c;
	my $num_views = ceil( $self->document->number_of_pages / $num_pages_per_view );
	my @grid_pages = part { int( $_ / $num_pages_per_view ) } 0 .. @page_numbers - 1;

	my @grid_collection = map {
		my @this_grid_page_idx = @$_;
		my @this_grid_pages = map {
			$page_numbers[$_]
		} @this_grid_page_idx;
		GridScheme->new( rows => $g_r, columns => $g_c, pages => \@this_grid_pages );
	} @grid_pages;

	return \@grid_collection;
}

method _build__subviews() {
	[
		map {
			Renard::Curie::Model::View::Grid::Subview->new(
				_grid_view => $self,
				_grid_scheme => $_,
			);
		} @{ $self->_grid_schemes }
	];
}

method _trigger__subview_idx() {
	$self->signal_emit( 'view-changed' );
}

method _update_subview_idx() {
	my $page_number = $self->page_number;
	my $subview_has_page = !! grep {
		$_ == $page_number
	} @{ $self->_grid_schemes->[$self->_subview_idx]->pages };
	if( ! $subview_has_page ) {
		my $idx = first {
			my $idx = $_;
			my $subview_pages = $self->_grid_schemes->[$idx]->pages;
			defined first { $_ == $page_number } @$subview_pages;
		} 0 .. @{ $self->_grid_schemes } - 1;
		$self->_subview_idx( $idx );
	}
}

method _trigger_page_number($page_number) {
	$self->_update_subview_idx;
}

method set_page_number_with_scroll( $page_number ) {
	$self->page_number( $page_number );
	$self->signal_emit( 'scroll-to-page', $page_number );
}

method scroll_emit() {
	$self->signal_emit( 'scroll-to-page', $self->page_number );
}

with qw(
	Renard::Curie::Model::View::Role::ForDocument
	Renard::Curie::Model::View::Role::Pageable
	Renard::Curie::Model::View::Role::SubviewPageable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Grid - A view model for grid-based views

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Renard::Curie::Model::View>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Model::View::Role::ForDocument>

=item * L<Renard::Curie::Model::View::Role::Pageable>

=item * L<Renard::Curie::Model::View::Role::SubviewPageable>

=back

=head1 ATTRIBUTES

=head2 view_options

A L<Renard::Curie::Model::ViewOptions> that defines how the grid layout
will be constructed.

Predicate: L<has_view_options>

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Initialises the L<Glib::Object> super-class.

=head1 METHODS

=head2 has_view_options

A predicate for the C<view_options> attribute.

=head2 zoom_level

Accessor for the view's zoom level.

=head2 set_page_number_with_scroll

Set page number then emit scroll event.

=head2 scroll_emit

Emit C<scroll-to-page> signal.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
