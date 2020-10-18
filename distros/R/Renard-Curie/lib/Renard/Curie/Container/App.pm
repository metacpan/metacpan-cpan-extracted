use Renard::Incunabula::Common::Setup;
package Renard::Curie::Container::App;
# ABSTRACT: A Bread::Board container for the application
$Renard::Curie::Container::App::VERSION = '0.005';
use Moose;
use Bread::Board::Declare;

# Subcomponents
has menu_bar => (
	is => 'ro',
	isa => 'Renard::Curie::Component::MenuBar',
	infer => 1,
	lifecycle => 'Singleton',
);

has outline => (
	is => 'ro',
	isa => 'Renard::Curie::Component::Outline',
	infer => 1,
	lifecycle => 'Singleton',
);

has log_window => (
	is => 'ro',
	isa => 'Renard::Curie::Component::LogWindow',
	infer => 1,
	lifecycle => 'Singleton',
);

has tts_window => (
	is => 'ro',
	isa => 'Renard::Curie::Component::TTSWindow',
	infer => 1,
	lifecycle => 'Singleton',
);

# Main component
has main_window => (
	is => 'ro',
	isa => 'Renard::Curie::Component::MainWindow',
	dependencies => [qw(log_window outline menu_bar view_manager tts_window)],
	lifecycle => 'Singleton',
);

has view_manager => (
	is => 'ro',
	isa => 'Renard::Curie::ViewModel::ViewManager',
	infer => 1,
	lifecycle => 'Singleton',
);

# App
has app => (
	is => 'ro',
	isa => 'Renard::Curie::App',
	infer => 1,
	lifecycle => 'Singleton',
);

method _test_current_view() {
	$self->view_manager->current_view;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Container::App - A Bread::Board container for the application

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moose::Meta::Class::__ANON__::SERIAL::35>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
