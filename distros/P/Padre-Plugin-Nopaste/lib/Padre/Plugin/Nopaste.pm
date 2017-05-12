package Padre::Plugin::Nopaste;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.08';

use Try::Tiny;
use Padre::Unload ();
use Padre::Logger qw( TRACE DEBUG );
use parent qw{
	Padre::Plugin
	Padre::Role::Task
};
use Padre::Plugin::Nopaste::Services;
use Carp;

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Nopaste
	Padre::Plugin::Nopaste::Task
	Padre::Plugin::Nopaste::Services
	Padre::Plugin::Nopaste::Preferences
	Padre::Plugin::Nopaste::FBP::Preferences
	App::Nopaste
	App::Nopaste::Service
	App::Nopaste::Service::Shadowcat
};


#######
# Define Plugin Name Spell Checker
#######
sub plugin_name {
	return Wx::gettext('Nopaste');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'         => '0.96',
		'Padre::Task'           => '0.96',
		'Padre::Unload'         => '0.96',
		'Padre::Logger'         => '0.96',
		'Padre::Wx'             => '0.96',
		'Padre::Wx::Role::Main' => '0.96',
	);
}

#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;
	my $nick   = 0;

	# Tests for externals used by Preference's
	if ( $config->identity_nickname ) {
		$nick = 1;
	} else {
		croak "\nYou need to set 'identity_nickname' \n Look in Tools -> Preferences -> Advance\n\n";
	}

	#Set/ReSet Config data
	if ($nick) {
		$self->_config;
	}

	return $nick;
}

#######
# Composed Method _config
# called on enable in plugin manager, bit like run/setup for a Plugin
#######
sub _config {
	my $self      = shift;
	my $config_db = $self->config_read;

	try {
		if ( defined $config_db->{Services} ) {
			my $tmp_services = $config_db->{Services};
			my $tmp_channel  = $config_db->{Channel};
			$self->config_write( {} );
			$config_db             = $self->config_read;
			$config_db->{Services} = $tmp_services;
			$config_db->{Channel}  = $tmp_channel;
			$self->config_write($config_db);
			return;
		} else {
			$self->config_write( {} );
			$config_db->{Services} = 'Shadowcat';
			$config_db->{Channel}  = '#padre';
			$self->config_write($config_db);
		}
	}
	catch {
		$self->config_write( {} );
		$config_db->{Services} = 'Shadowcat';
		$config_db->{Channel}  = '#padre';
		$self->config_write($config_db);
		return;
	};

	return;
}

#######
# plugin menu
#######
sub menu_plugins {
	my $self = shift;
	my $main = $self->main;

	# Create a manual menu item
	my $menu_item = Wx::MenuItem->new( undef, -1, $self->plugin_name . "\tCtrl+Shift+V", );
	Wx::Event::EVT_MENU(
		$main,
		$menu_item,
		sub {
			$self->paste_it;
		},
	);

	return $menu_item;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}


#######
# plugin_preferences
#######
sub plugin_preferences {
	my $self = shift;
	my $main = $self->main;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	try {
		require Padre::Plugin::Nopaste::Preferences;
		$self->{dialog} = Padre::Plugin::Nopaste::Preferences->new($main);
		$self->{dialog}->ShowModal;
	}
	catch {
		$self->main->error( sprintf Wx::gettext('Error: %s'), $_ );
	};

	return;
}


#######
# paste_it
#######
sub paste_it {
	my $self   = shift;
	my $main   = $self->main;
	my $config = $main->config;

	my $output   = $main->output;
	my $current  = $self->current;
	my $document = $current->document;

	my $full_text     = $document->text_get;
	my $selected_text = $current->text;

	my $config_db = $self->config_read;

	TRACE('paste_it: start task to nopaste') if DEBUG;

	my $text = $selected_text || $full_text;
	return unless defined $text;

	require Padre::Plugin::Nopaste::Task;

	# # Fire the task
	$self->task_request(
		task      => 'Padre::Plugin::Nopaste::Task',
		text      => $text,
		nick      => $config->identity_nickname,
		services  => $config_db->{Services},
		channel   => $config_db->{Channel},
		on_finish => 'on_finish',
	);

	# say 'end paste_it';
	return;
}

#######
# on completion of task do this
#######
sub on_finish {
	my $self = shift;
	my $task = shift;

	TRACE('on_finish: nopaste_response') if DEBUG;


	# Generate the dump string and set into the output window
	my $main = $self->main;
	$main->show_output(1);
	my $output = $main->output;
	$output->clear;
	if ( $task->{error} ) {
		$output->AppendText('Something went wrong, here is the response we got:');
	}
	$output->AppendText( $task->{message} );

	return;

}


#######
# Add icon to Plugin
#######
sub plugin_icon {
	my $class = shift;
	my $share = $class->plugin_directory_share or return;
	my $file  = File::Spec->catfile( $share, 'icons', '16x16', 'nopaste.png' );
	return unless -f $file;
	return unless -r $file;
	return Wx::Bitmap->new( $file, Wx::wxBITMAP_TYPE_PNG );
}

#######
# Add Preferences to Context Menu
#######
sub event_on_context_menu {
	my ( $self, $document, $editor, $menu, $event ) = @_;

	#Test for valid file type
	return if not $document->filename;

	$menu->AppendSeparator;

	my $item = $menu->Append( -1, Wx::gettext('Nopaste Preferences...') );
	Wx::Event::EVT_MENU(
		$self->main,
		$item,
		sub { $self->plugin_preferences },
	);

	return;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Padre::Plugin::Nopaste - NoPaste plugin for Padre, The Perl IDE.

=head1 VERSION

version: 0.08

=head1 SYNOPSIS

Send code to a nopaste website from Padre.

    $ padre
    Ctrl+Shift+V

=head1 DESCRIPTION

This plugin allows one to send stuff from Padre to a nopaste website
with Ctrl+Shift+V, allowing for easy code / whatever sharing without
having to open a browser.

It is using C<App::Nopaste> underneath, so check this module's pod for
more information.


=head1 METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::Nopaste> defines a plugin which follows C<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item * padre_interfaces()

=item * plugin_icon()

=item * plugin_name()

=item * clean_dialog()

=item * menu_plugins()

=item * plugin_disable()

=item * plugin_enable()

=item * plugin_preferences()

Spelling preferences window normally access via Plug-in Manager

=item * event_on_context_menu()

Add access to spelling preferences window.

=back


=head2 Standard Padre::Role::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by C<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item * paste_it()

=item * on_finish()

Callback for task run by nopaste().

=back

=head2 Internal Methods

=over 4

=item * _config()


=back

=head1 BUGS AND LIMITATIONS

event_on_context_menu() is not supported in Padre 0.96 and below.

=head1 SEE ALSO

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.


You can also look for information on this module at:

=over 4

=item * Padre-Plugin-Nopaste web page

L<http://padre.perlide.org/trac/wiki/PadrePluginNopaste>

=item * Our svn repository

L<http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste>,
 and can be browsed at
  L<http://padre.perlide.org/browser/trunk/Padre-Plugin-Nopaste>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Nopaste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Nopaste>

=back


=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

=head2 CONTRIBUTORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

Alexandr Ciornii E<lt>alexchorny@gmail.comE<gt>


=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2009-2013 the Padre::Plugin::Nopaste L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

