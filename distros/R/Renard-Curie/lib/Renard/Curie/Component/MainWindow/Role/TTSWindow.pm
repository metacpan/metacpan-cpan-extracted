use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::TTSWindow;
# ABSTRACT: Role for TTS window
$Renard::Curie::Component::MainWindow::Role::TTSWindow::VERSION = '0.005';
use Moo::Role;
use Renard::Curie::Component::Outline;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Renard::Incunabula::Document::Types qw(DocumentModel);

use Glib 'TRUE', 'FALSE';

requires 'content_box';

has tts_window => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::TTSWindow'],
);

after setup_window => method() {
	if( $^O ne 'MSWin32' ) {
		$self->tts_window->show_all;
		$self->loop->add( $self->tts_window->synth_function );
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::TTSWindow - Role for TTS window

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 tts_window

A L<Renard::Curie::Component::TTSWindow>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
