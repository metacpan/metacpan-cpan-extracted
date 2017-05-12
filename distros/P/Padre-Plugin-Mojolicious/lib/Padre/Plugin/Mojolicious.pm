package Padre::Plugin::Mojolicious;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.06';

use Padre::Plugin ();

our @ISA = 'Padre::Plugin';

######################################################################
# Padre Integration

sub padre_interfaces {
	'Padre::Plugin' => 0.92,;
}


######################################################################
# Padre::Plugin Methods

sub plugin_name {
	Wx::gettext('Mojolicious');
}

sub plugin_disable {
	require Padre::Unload;
	Padre::Unload->unload('Padre::Plugin::Mojolicious::NewApp');
	Padre::Unload->unload('Padre::Plugin::Mojolicious::Util');
	Padre::Unload->unload('Mojolicious');
}

# The command structure to show in the Plugins menu
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('New Mojolicious Application') => sub {
			require Padre::Plugin::Mojolicious::NewApp;
			Padre::Plugin::Mojolicious::NewApp->new( $self->main )->run;
			return;
		},

		'---' => undef,

		Wx::gettext('Start Web Server') => sub {
			$self->on_start_server;
		},

		Wx::gettext('Stop Web Server') => sub {
			$self->on_stop_server;
		},

		'---' => undef,

		Wx::gettext('Mojolicious Online References') => [
			Wx::gettext('Mojolicious Manual') => sub {
				Padre::Wx::launch_browser('http://mojolicio.us/perldoc');
			},
			Wx::gettext('Mojolicious Website') => sub {
				Padre::Wx::launch_browser('http://www.mojolicious.org/');
			},
			Wx::gettext('Mojolicious Community Live Support') => sub {
				Padre::Wx::launch_irc( 'irc.perl.org' => 'mojo' );
			},

		],

		'---' => undef,

		Wx::gettext('About') => sub {
			$self->on_show_about;
		},
	];
}

sub on_start_server {
	my $self = shift;
	my $main = $self->main;

	require Padre::Plugin::Mojolicious::Util;
	my $project_dir = Padre::Plugin::Mojolicious::Util::get_document_base_dir();

	my $server_filename = Padre::Plugin::Mojolicious::Util::get_mojolicious_project_name($project_dir);

	my $server_full_path = File::Spec->catfile( $project_dir, 'script', $server_filename );
	unless ( -e $server_full_path ) {
		Wx::MessageBox(
			sprintf(
				Wx::gettext(
					"Mojolicious application script not found at\n%s\n\nPlease make sure the active document is from your Mojolicious project."
				),
				$server_full_path
			),
			Wx::gettext('Server not found'),
			Wx::wxOK, $main
		);
		return;
	}

	# Go to the selected file's directory
	# (Mojolicious instructs us to always run their scripts
	#  from the basedir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;

	require Padre::Perl;
	my $command = Padre::Perl->cperl . ' ' . File::Spec->catfile( 'script', $server_filename ) . ' daemon';

	$main->run_command($command);

	# restore current dir
	chdir $pwd;

	# TODO: actually check whether this is true.
	my $ret = Wx::MessageBox(
		Wx::gettext('Web server appears to be running. Launch web browser now?'),
		Wx::gettext('Start Web Browser?'),
		Wx::wxYES_NO | Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		Padre::Wx::launch_browser('http://localhost:3000');
	}

	# TODO: handle menu greying

	return;
}

sub on_stop_server {
	my $self = shift;
	my $main = $self->main;

	# TODO: Make this actually call
	# Run -> Stop
	if ( $main->{command} ) {
		my $processid = $main->{command}->GetProcessId();
		kill( 9, $processid );

		# $main->{command}->TerminateProcess;
	}
	delete $main->{command};
	$main->menu->run->enable;
	$main->output->AppendText( "\n" . Wx::gettext('Web server stopped successfully.') . "\n" );
	return;
}

sub on_show_about {
	require Mojolicious;
	require Padre::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Padre::Plugin::Mojolicious');
	$about->SetDescription( Wx::gettext('Mojolicious support for Padre') . "\n\n"
			. sprintf( Wx::gettext('This system is running Mojolicious version %s'), $Mojolicious::VERSION )
			. "\n" );
	$about->SetVersion($Padre::Plugin::Mojolicious::VERSION);
	Padre::Unload->unload('Mojolicious');
	Wx::AboutBox($about);
	return;
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::Mojolicious - Mojolicious support for Padre

=head1 SYNOPSIS

	cpan Padre::Plugin::Mojolicious;

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 'New Mojolicious Application'

This options lets you create a new Mojolicious application.

=head2 Start Web Server

This option will automatically spawn your application's development web server. Once it's started, it will ask to open your default web browser to view your application running.

Note that this works like Padre's "run" menu option, so any other execution it will be disabled while your server is running.

=head2 Stop Web Server

This option will stop the development web server for you.

=head2 Mojolicious Online References

This menu option contains a series of external reference links on Mojolicious. Clicking on each of them will point your default web browser to their websites.

=head2 About

Shows a nice about box with this module's name and version.

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-mojolicious at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Mojolicious>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Padre::Plugin::Mojolicious


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Mojolicious>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Mojolicious>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Mojolicious>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Mojolicious/>

=back

=head1 SEE ALSO

L<Mojolicious>, L<Padre>

=head1 AUTHORS

=over 4

=item *

Breno G. de Oliveira <garu@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Breno G. de Oliveira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
