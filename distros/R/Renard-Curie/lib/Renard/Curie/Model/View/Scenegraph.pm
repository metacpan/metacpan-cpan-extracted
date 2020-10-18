use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Scenegraph;
# ABSTRACT: A Jacquard Scene graph factory
$Renard::Curie::Model::View::Scenegraph::VERSION = '0.005';
use Mu;

use feature qw(current_sub);

use Renard::Curie::Model::View::Grid::PageActor;
use Intertangle::Jacquard::Layout::Grid;
use Intertangle::Jacquard::Layout::Box;

my $_LayoutGroup = Moo::Role->create_class_with_roles(
	'Intertangle::Jacquard::Actor' => qw(
	Intertangle::Jacquard::Role::Geometry::Position2D
	Intertangle::Jacquard::Role::Geometry::Size2D
	Intertangle::Jacquard::Role::Render::QnD::SVG::Group
	Intertangle::Jacquard::Role::Render::QnD::Cairo::Group
	Intertangle::Jacquard::Role::Render::QnD::Layout
	Intertangle::Jacquard::Role::Render::QnD::Size::Direct
	Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct
));

has box_layout => (
	is => 'ro',
	default => sub { 1 },
);

has view_manager => (
	is => 'ro',
	required => 1,
);

has view => (
	is => 'ro',
	required => 1,
);

lazy graph => method() {
	my $graph = $self->create_scene_graph;
	$self->update_layout($graph);

	$graph;
};

method create_group( :$grid_scheme, :$margin = 10 ) {
	my @pages = @{ $grid_scheme->pages };

	my $group = $_LayoutGroup->new(
		layout => Intertangle::Jacquard::Layout::Grid->new(
			rows => $grid_scheme->rows,
			columns => $grid_scheme->columns ),
	);

	my $start = $pages[0];
	my $end = $pages[-1];

	for my $page_no ($start..$end) {
		my $actor = Renard::Curie::Model::View::Grid::PageActor->new(
			document => $self->view_manager->current_document,
			page_number => $page_no,
		);
		if( $self->box_layout ) {
			my $box = $_LayoutGroup->new(
				layout => Intertangle::Jacquard::Layout::Box->new( margin => $margin ),
			);
			$box->add_child( $actor );
			$group->add_child( $box );
		} else {
			$group->add_child( $actor );
		}
	}

	$group;
}

method create_scene_graph() {
	my $grid_scheme = $self->view
		->_current_subview->_grid_scheme;

	my $group = $self->create_group( grid_scheme => $grid_scheme, margin => 10);

	$group->x->value( 0 );
	$group->y->value( 0 );

	return $group;
}

sub _update_layouts {
	my ($g) = @_;
	__SUB__->($_) for @{ $g->children };
	$g->update_layout if $g->can('update_layout');
}

method update_layout($group) {
	_update_layouts($group);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Scenegraph - A Jacquard Scene graph factory

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 box_layout

A C<Bool> for whether to use box layout or not.

=head2 view_manager

The view manager for this scene graph (required).

=head2 view

The view for this scene graph (required).

=head1 METHODS

=head2 create_group

Creates a grid layout group given a grid scheme.

=head2 create_scene_graph

Creates and sets up a scene graph for the current view.

=head2 update_layout

Update layouts for scene graph.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
