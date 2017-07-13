use Renard::Incunabula::Common::Setup;
package Renard::Curie::App;
# ABSTRACT: A document viewing application
$Renard::Curie::App::VERSION = '0.003';
use Moo 2.001001;

use Renard::Incunabula::Frontend::Gtk3::Helper;

use File::Spec;
use File::Basename;
use Module::Util qw(:all);
use Renard::Incunabula::Common::Types qw(InstanceOf Str DocumentModel);
use Getopt::Long::Descriptive;

use MooX::Role::Logger ();

use Renard::Curie::Component::MainWindow;
use Renard::Curie::ViewModel::ViewManager;

has main_window => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::MainWindow'],
);

has view_manager => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::ViewModel::ViewManager'],
);

method process_arguments() {
	my ($opt, $usage) = describe_options(
		"%c %o <filename>",
		[ 'version',        "print version and exit"                             ],
		[ 'short-version',  "print just the version number (if exists) and exit" ],
		[ 'help',           "print usage message and exit"                       ],
	);

	print($usage->text), exit if $opt->help;

	if($opt->version) {
		say("Project Renard Curie @{[ _get_version() ]}");
		say("Distributed under the same terms as Perl 5.");
		exit;
	}

	if($opt->short_version) {
		say(_get_version()), exit
	}

	my $pdf_filename = shift @ARGV;

	if( $pdf_filename ) {
		$self->_logger->infof("opening the file %s", $pdf_filename);
		$self->view_manager->open_pdf_document( $pdf_filename );
	}
}

method main() {
	$self = __PACKAGE__->new unless ref $self;
	$self->process_arguments;
	$self->main_window->show_all;
	$self->run;
}

method run() {
	$self->_logger->info("starting the Gtk main event loop");
	Gtk3::main;
}

fun _get_version() :ReturnType(Str) {
	return $Renard::Curie::App::VERSION // 'dev'
}

with qw(
	MooX::Role::Logger
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::App - A document viewing application

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<MooX::Role::Logger>

=back

=head1 FUNCTIONS

=head2 main

  fun main()

Application entry point.

=head2 _get_version

  fun _get_version() :ReturnType(Str)

Returns the version of the application if there is one.
Otherwise returns the C<Str> C<'dev'> to indicate that this is a
development version.

=head1 ATTRIBUTES

=head2 main_window

The toplevel L<Renard::Curie::Component::MainWindow> component for this application.

=head2 view_manager

The view manager model for this application.

=head1 METHODS

=head2 process_arguments

  method process_arguments()

Processes arguments given in C<@ARGV>.

=head2 run

  method run()

Displays L</window> and starts the L<Gtk3> event loop.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
