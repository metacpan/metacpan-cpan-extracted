use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager::Role::ViewOptions;
# ABSTRACT: A role for the view options
$Renard::Curie::ViewModel::ViewManager::Role::ViewOptions::VERSION = '0.005';
use Moo::Role;

use Renard::Incunabula::Common::Types qw(InstanceOf);

use Renard::Curie::Model::ViewOptions;
use Renard::Curie::Model::View::Grid;

has current_view => (
	is => 'rw',
	isa => InstanceOf['Renard::Curie::Model::View'],
	trigger => 1, # _trigger_current_view
);

method _trigger_current_view($view) {
	$view->signal_connect( 'view-changed', sub {
		$self->signal_emit( 'update-view' => $self->current_view );
	});
	$self->signal_emit( 'update-view' => $view );
}

has view_options => (
	is => 'rw',
	lazy => 1,
	builder => sub {
		my $view_options = Renard::Curie::Model::ViewOptions->new;
	},
	trigger => 1, # _trigger_view_options
	clearer => 1, # clear_view_options
);


method _trigger_view_options( $new_view_options ) {
	my $page_number = $self->current_view->page_number;
	my $view = Renard::Curie::Model::View::Grid->new(
		document => $self->current_document,
		view_options => $new_view_options,
	);
	$self->current_view( $view );

	if( defined $page_number ) {
		$view->set_page_number_with_scroll( $page_number );
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager::Role::ViewOptions - A role for the view options

=head1 VERSION

version 0.005

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
