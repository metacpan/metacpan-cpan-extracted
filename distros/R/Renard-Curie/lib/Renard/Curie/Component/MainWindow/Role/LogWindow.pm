use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::LogWindow;
# ABSTRACT: Role for log window
$Renard::Curie::Component::MainWindow::Role::LogWindow::VERSION = '0.004';
use Moo::Role;

use Renard::Curie::Component::LogWindow;
use Renard::Incunabula::Common::Types qw(InstanceOf);

use Log::Any::Adapter;


has log_window => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::LogWindow'],
);

after setup_window => method() {
	Log::Any::Adapter->set('+Renard::Curie::Log::Any::Adapter::LogWindow',
		log_window => $self->log_window );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::LogWindow - Role for log window

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 log_window

A L<Renard::Curie::Component::LogWindow> for the application's logging.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
