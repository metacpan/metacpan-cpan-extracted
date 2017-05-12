package Padre::Plugin::Catalyst;
use base 'Padre::Plugin';

use warnings;
use strict;

use Padre::Util ('_T');
use Padre::Perl;

our $VERSION = '0.09';

# The plugin name to show in the Plugin Manager and menus
sub plugin_name {'Catalyst'}

# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
	'Padre::Plugin' => 0.43,

		#    'Padre::Document::Perl' => 0.16,
		#    'Padre::Wx::Main'       => 0.16,
		#    'Padre::DB'             => 0.16,
}

sub plugin_icon {
	my $icon = [
		'16 16 46 1',       '   c None',        '.  c #D15C5C',       '+  c #E88888', '@  c #E10000',
		'#  c #D03131',     '$  c #D26262',     '%  c #D26161',       '&  c #E99F9F', '*  c #EFACAC',
		'=  c #EFADAD',     '-  c #E79090',     ';  c #D14949',       '>  c #D22727', ',  c #E26666',
		'\'  c #E26363',    ')  c #E26464',     '!  c #D42A2A',       '~  c #D40101', '{  c #D50B0B',
		']  c #D71313',     '^  c #D50C0C',     '/  c #D40404',       '(  c #D26767', '_  c #DF5353',
		':  c #E15B5B',     '<  c #D95D5D',     '[  c #D21313',       '}  c #D30000', '|  c #DA0000',
		'1  c #D90000',     '2  c #D31111',     '3  c #D14646',       '4  c #DC1313', '5  c #EC0000',
		'6  c #E20000',     '7  c #F00000',     '8  c #F20000',       '9  c #D33232', '0  c #D64646',
		'a  c #D46969',     'b  c #D35555',     'c  c #D23A3A',       'd  c #E89090', 'e  c #E98E8E',
		'f  c #D60000',     'g  c #D70101',     '                ',   '            .   ',
		'            +   ', '            @#  ', '                ',   '                ',
		'        $%      ', '       &*=-;    ', '      >,\'\')!    ', '      ~{]]^/    ',
		'(_: < [}|1}2    ', '345    67869    ', ' 0a         b c ',   '              de',
		'              fg', '                ',
	];
	return Wx::Bitmap->newFromXPM($icon);
}


# we used to be happy and innocent users of
# menu_plugins_simple() interface, until we figured
# we needed to disable one of the menu items upon startup.
# Currently the only way (to our knowledge) to do so
# is to loose the "simple" interface and go hardcore
# with menu_plugins(). However, this did rose the issue
# that maybe there should be a quick access to plugin
# menus, and/or an extra parameter to simple() that would
# set the menu item as disabled.
#
# another thing that isn't currently found is an event hook to
# document change, like the one that shows/hides the "Perl" menu.
# having this to plugins would be sweet, or at least a menu
# construction hook called just before the menu is displayed,
# like a menu_plugins_on_sight()  :)

sub menu_plugins {
	my $self = shift;
	my $main = shift;

	# Create a simple menu with a single About entry
	my $menu = Wx::Menu->new;
	Wx::Event::EVT_MENU(
		$main,
		$menu->Append( -1, _T('New Catalyst Application') ),
		sub {
			require Padre::Plugin::Catalyst::NewApp;
			Padre::Plugin::Catalyst::NewApp::on_newapp();
			return;
		},
	);
	my $menu_new = Wx::Menu->new;
	$menu->Append( -1, _T('Create new...'), $menu_new );
	Wx::Event::EVT_MENU(
		$main,
		$menu_new->Append( -1, _T('Model') ),
		sub {
			require Padre::Plugin::Catalyst::Helper;
			Padre::Plugin::Catalyst::Helper::on_create_model();
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$menu_new->Append( -1, _T('View') ),
		sub {
			require Padre::Plugin::Catalyst::Helper;
			Padre::Plugin::Catalyst::Helper::on_create_view();
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$menu_new->Append( -1, _T('Controller') ),
		sub {
			require Padre::Plugin::Catalyst::Helper;
			Padre::Plugin::Catalyst::Helper::on_create_controller();
		},
	);

	$menu->AppendSeparator;
	Wx::Event::EVT_MENU(
		$main,
		$menu->Append( -1, _T('Start Web Server') ),
		sub { $self->on_start_server },
	);

	# when we start the plugin, the "stop web server" option
	# is disabled.
	my $stop_server_item = $menu->Append( -1, _T('Stop Web Server') );
	Wx::Event::EVT_MENU(
		$main,
		$stop_server_item,
		sub { $self->on_stop_server },
	);
	$stop_server_item->Enable(0);

	$menu->AppendSeparator;
	my $docs_menu = Wx::Menu->new;
	$menu->Append( -1, _T('Catalyst Online References'), $docs_menu );

	my $tutorial_menu = Wx::Menu->new;
	$docs_menu->Append( -1, _T('Beginner\'s Tutorial'), $tutorial_menu );
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('Overview') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial');
		},
	);

	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('1. Introduction') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::01_Intro');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('2. Catalyst Basics') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::02_CatalystBasics');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('3. More Catalyst Basics') ),
		sub {
			Padre::Wx::launch_browser(
				'http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::03_MoreCatalystBasics');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('4. Basic CRUD') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::04_BasicCRUD');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('5. Authentication') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::05_Authentication');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('6. Authorization') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::06_Authorization');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('7. Debugging') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::07_Debugging');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('8. Testing') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::08_Testing');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('9. Advanced CRUD') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::09_AdvancedCRUD');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$tutorial_menu->Append( -1, _T('10. Appendices') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Tutorial::10_Appendices');
		},
	);

	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Catalyst Cookbook') ),
		sub {
			Padre::Wx::launch_browser('http://search.cpan.org/perldoc?Catalyst::Manual::Cookbook');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Recommended Plugins') ),
		sub {
			Padre::Wx::launch_browser('http://dev.catalystframework.org/wiki/recommended_plugins');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Catalyst Community Live Support') ),
		sub {
			Padre::Wx::launch_irc( 'irc.perl.org' => 'catalyst' );
		},
	);

	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Examples') ),
		sub {
			Padre::Wx::launch_browser('http://dev.catalyst.perl.org/repos/Catalyst/trunk/examples/');
		},
	);

	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Catalyst Wiki') ),
		sub {
			Padre::Wx::launch_browser('http://dev.catalystframework.org/wiki/');
		},
	);
	Wx::Event::EVT_MENU(
		$main,
		$docs_menu->Append( -1, _T('Catalyst Website') ),
		sub {
			Padre::Wx::launch_browser('http://www.catalystframework.org/');
		},
	);

	$menu->AppendSeparator;
	Wx::Event::EVT_MENU(
		$main,
		$menu->Append( -1, _T('Update Application Scripts') ),
		sub { $self->on_update_script },
	);

	$menu->AppendSeparator;
	Wx::Event::EVT_MENU(
		$main,
		$menu->Append( -1, _T('About') ),
		sub { $self->on_show_about },
	);

	# Return it and the label for our plug-in
	return ( $self->plugin_name => $menu );

	#TODO: add status bar comment for each menu entry.
	# look into Padre::Wx::Menu and wxWidgets for $item->SetHelp('foo')
}


sub event_on_context_menu {
	my ( $self, $document, $editor, $menu, $event ) = (@_);

	my $pos;
	if ( $event->isa("Wx::MouseEvent") ) {
		my $point = $event->GetPosition();
		if ( $point != Wx::wxDefaultPosition ) {

			# Then it is really a mouse event...
			# On Windows, context menu is faked
			# as a Mouse event
			$pos = $editor->PositionFromPoint($point);
		}
	}

	# Fall back to the cursor position if necessary
	$pos = $editor->GetCurrentPos() unless ($pos);

	my $template = _get_template( $editor, $pos );
	if ($template) {
		$menu->AppendSeparator;
		my $item = $menu->Append(
			-1,
			sprintf( _T("Open Template '%s'"), $template ),
		);
		Wx::Event::EVT_MENU(
			$self->main,
			$item,
			sub { \&_open_template( shift, $template ) },
		);
	}

}

sub _open_template {
	my ( $main, $template ) = (@_);

	require File::Spec;
	require File::Find;
	require Padre::Plugin::Catalyst::Util;

	my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir() || return;
	my $template_dir = File::Spec->catdir( $project_dir, 'root' );

	my @files;
	File::Find::find(
		sub {
			if ( $File::Find::name =~ /$template$/ ) {
				push @files, $File::Find::name;
			}
		},
		$template_dir
	);

	unless (@files) {
		Wx::MessageBox(
			sprintf(
				_T("Template '%s' not found in '%s'"),
				$template, $template_dir
			),
			_T('Error'),
			Wx::wxOK, $main
		);
	}

	# if we get over one result, we default to the
	# shortest path
	my $file = shift @files;
	foreach (@files) {
		$file = $_ if length($file) > length($_);
	}
	$main->setup_editors($file);
}

sub _get_template {
	my ( $editor, $pos ) = (@_);

	my $line         = $editor->LineFromPosition($pos);
	my $line_start   = $editor->PositionFromLine($line);
	my $line_end     = $editor->GetLineEndPosition($line);
	my $cursor_col   = $pos - $line_start;
	my $line_content = $editor->GetTextRange( $line_start, $line_end );

	#TODO: improve template detection
	if ( $line_content =~ /([\/\w]+\.tt\d?)/ ) {
		return $1;
	}
}

sub on_update_script {
	my $main = Padre->ide->wx->main;

	require File::Spec;
	require Padre::Plugin::Catalyst::Util;
	my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir() || return;

	my @dir     = File::Spec->splitdir($project_dir);
	my $project = $dir[-1];
	$project =~ s{-}{::}g;

	# go to the selected file's PARENT directory
	# (so we can run catalyst.pl on the project dir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;
	chdir File::Spec->updir;

	$main->run_command("catalyst.pl -force -scripts $project");

	# restore current dir
	chdir $pwd;
}

sub on_start_server {
	my $self = shift;

	#TODO FIXME: if the user closed the panel,
	# how do we know? and how do we show it again?
	# as it is, Padre crashes :(
	#Padre::Current->main->bottom->show($self->panel);

	my $main = Padre->ide->wx->main;

	require File::Spec;
	require Padre::Plugin::Catalyst::Util;
	my $project_dir = Padre::Plugin::Catalyst::Util::get_document_base_dir() || return;

	my $server_filename = Padre::Plugin::Catalyst::Util::get_catalyst_project_name($project_dir);

	$server_filename .= '_server.pl';

	my $server_full_path = File::Spec->catfile( $project_dir, 'script', $server_filename );
	if ( !-e $server_full_path ) {
		Wx::MessageBox(
			sprintf(
				_T( "Catalyst development web server not found at\n%s\n\nPlease make sure the active document is from your Catalyst project."
				),
				$server_full_path
			),
			_T('Server not found'),
			Wx::wxOK, $main
		);
		return;
	}

	# go to the selected file's directory
	# (catalyst instructs us to always run their scripts
	#  from the basedir)
	my $pwd = Cwd::cwd();
	chdir $project_dir;

	my $perl = Padre::Perl->perl;
	my $command = "$perl " . File::Spec->catfile( 'script', $server_filename );
	$command .= ' -r ' if $self->panel->{checkbox}->IsChecked;

	#$main->run_command($command);
	# somewhat the same as $main->run_command,
	# but in our very own panel, and with our own rigs
	$self->run_command($command);

	# restore current dir
	chdir $pwd;

	# handle menu graying
	Padre::Plugin::Catalyst::Util::toggle_server_menu(0);
	$self->panel->toggle_panel(0);

	# TODO: actually check whether this is true.
	my $ret = Wx::MessageBox(
		_T('Web server appears to be running. Launch web browser now?'),
		_T('Start Web Browser?'),
		Wx::wxYES_NO | Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		Padre::Wx::launch_browser('http://localhost:3000');
	}

	return;
}


### run_command() adapted from Padre::Wx::Main's version
sub run_command {
	my ( $self, $command ) = (@_);

	# clear the panel
	$self->panel->output->Remove( 0, $self->panel->output->GetLastPosition );

	# If this is the first time a command has been run,
	# set up the ProcessStream bindings.
	unless ($Wx::Perl::ProcessStream::VERSION) {
		require Wx::Perl::ProcessStream;
		if ( $Wx::Perl::ProcessStream::VERSION < .20 ) {
			$self->main->error(
				sprintf(
					_T(       'Wx::Perl::ProcessStream is version %s'
							. ' which is known to cause problems. Get at least 0.20 by typing'
							. "\ncpan Wx::Perl::ProcessStream"
					),
					$Wx::Perl::ProcessStream::VERSION
				)
			);
			return 1;
		}

		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				my $outpanel = $_[0]; #->{panel};
				$outpanel->style_good;
				$outpanel->AppendText( $_[1]->GetLine . "\n" );
				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDERR(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				my $outpanel = $_[0]; #->{panel};
				$outpanel->style_neutral;
				$outpanel->AppendText( $_[1]->GetLine . "\n" );

				return;
			},
		);
		Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT(
			$self->panel->output,
			sub {
				$_[1]->Skip(1);
				$_[1]->GetProcess->Destroy;
				delete $self->{server};
			},
		);
	}

	# Start the command
	my $process = Wx::Perl::ProcessStream::Process->new(
		$command,
		"Run $command",
		$self->panel->output
	);
	$self->{server} = $process->Run;

	# Check if we started the process or not
	unless ( $self->{server} ) {

		# Failed to start the command. Clean up.
		Wx::MessageBox(
			sprintf( _T("Failed to start server via '%s'"), $command ),
			_T("Error"), Wx::wxOK, $self
		);

		#		$self->menu->run->enable;
	}

	return;
}

sub on_stop_server {
	my $self = shift;

	#TODO FIXME: if the user closed the panel,
	# how do we know? and how do we show it again?
	# as it is, Padre crashes :(
	#Padre::Current->main->bottom->show($self->panel);

	if ( $self->{server} ) {
		my $processid = $self->{server}->GetProcessId();
		kill( 9, $processid );

		#$self->{server}->TerminateProcess;
	}
	delete $self->{server};

	$self->panel->output->AppendText( "\n" . _T('Web server stopped successfully.') . "\n" );

	# handle menu graying
	require Padre::Plugin::Catalyst::Util;
	Padre::Plugin::Catalyst::Util::toggle_server_menu(1);
	$self->panel->toggle_panel(1);

	return;
}

sub on_show_about {
	require Catalyst;
	require Class::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Catalyst");
	$about->SetDescription( _T('Catalyst support for Padre') . "\n\n"
			. _T('This system is running Catalyst version')
			. " $Catalyst::VERSION\n" );
	$about->SetVersion($VERSION);
	Class::Unload->unload('Catalyst');

	Wx::AboutBox($about);
	return;
}

sub plugin_enable {
	my $self = shift;

	require Padre::Plugin::Catalyst::Panel;
	$self->{panel} = Padre::Plugin::Catalyst::Panel->new($self);

	Padre::Current->main->bottom->show( $self->{panel} );

	# load Catalyst main menu
	$self->editor_changed;

	# TODO: Please uncomment this to test the Catalyst side-panel
	#    require Padre::Plugin::Catalyst::Outline;
	#    $self->{outline} = Padre::Plugin::Catalyst::Outline->new($self);

}

sub panel { return shift->{panel} }

sub plugin_disable {
	my $self = shift;

	#    $self->panel->Destroy;
	Padre::Current->main->bottom->hide( $self->{panel} );
	$self->on_stop_server;


	# cleanup loaded classes
	require Class::Unload;
	Class::Unload->unload('Padre::Plugin::Catalyst::NewApp');
	Class::Unload->unload('Padre::Plugin::Catalyst::Helper');
	Class::Unload->unload('Padre::Plugin::Catalyst::Util');
	Class::Unload->unload('Padre::Plugin::Catalyst::Panel');
	Class::Unload->unload('Catalyst');
}

# FIXME: Padre does *NOT* seem to call this if a document is closed.
sub editor_changed {
	my $self = shift;
	my $document = $self->main->current->document || return $self->enable(0);

	#$document->{menu} = [] if (!defined($document->{menu})) or (ref($document->{menu}) ne 'ARRAY');
	#$document->{menu} = [grep (!/^menu\.Catalyst$/,@{$document->{menu}}) ];

	# when not inside a catalyst project, disable stuff
	my $toggle = 0;
	require Padre::Plugin::Catalyst::Util;
	if ( Padre::Plugin::Catalyst::Util::in_catalyst_project( $document->filename ) ) {

		# enable Catalyst main menu
		#push @{$document->{menu}}, 'menu.Catalyst';
		$toggle = 1;
	}

	# enable/disable Catalyst panel and menu entries
	$self->enable($toggle);
}

# this method is invoked when the active document
# is **NOT** part of a Catalyst project
sub enable {
	my ( $self, $toggle ) = (@_);
	my $is_server_on = ( defined $self->{server} ? 1 : 0 );

	# freeze menu entries
	# FIXME: this isn't working during startup
	require Padre::Plugin::Catalyst::Util;
	Padre::Plugin::Catalyst::Util::toggle_menu_items( $toggle, $is_server_on );

	# freeze the panel
	$self->panel->{button}->Enable($toggle);
	unless ($is_server_on) {
		$self->panel->{checkbox}->Enable($toggle);
	}
}


42;
__END__

=head1 NAME

Padre::Plugin::Catalyst - Catalyst helper interface for Padre

=head1 SYNOPSIS

	cpan install Padre::Plugin::Catalyst;

Then use it via L<Padre>, The Perl IDE.

=head1 IDEAS WANTED!

How can this Plugin further improve your Catalyst development experience? Please let us know! We are always looking for new ideas and wishlists on how to improve it even more, so drop us a line via email, RT or by joining us via IRC in #padre, right at irc.perl.org (if you are using Padre, you can do this by choosing 'Help->Live Support->Padre Support').

=head1 DESCRIPTION

As all Padre plugins, after installation you need to enable it via "Plugins->Plugin Manager".

Once you enable it, you should see a 'Catalyst Dev Server' panel on the bottom of your screen (probably next to your 'output' tab). This panel lets you start/stop your application's development server, and also set the auto-restart option for the server to reload itself whenever you change your application's modules or configuration files.

You'll also get a brand new menu (Plugins->Catalyst) with the following options:

=head2 'New Catalyst Application'

This options lets you create a new Catalyst application.

=head2 'Create new...'

The Catalyst helper lets you automatically create stub classes for your application's MVC components. With this menu option not only can you select your component's name but also its type. For instance, if you select "create new view" and have the L<Catalyst::Helper::View::TT> module installed on your system, the "TT" type will be available for you).

Of course, the available components are:

=over 4

=item * 'Model'

=item * 'View'

=item * 'Controller'

=back

=head2 'Start Web Server'

This option will automatically spawn your application's development web server. Once it's started, it will ask to open your default web browser to view your application running.

The server output should appear in your "Catalyst Dev Server" panel.

=head2 'Stop Web Server'

This option will stop the development web server for you.

=head2 'Catalyst Online References'

This menu option contains a series of external reference links on Catalyst. Clicking on each of them will point your default web browser to their websites.

=head2 'Update Application Scripts'

This option lets you update your application's scripts, upgrading it to a new version of Catalyst (if available)

=head2 'About'

Shows a nice about box with this module's name and version, as well as your installed Catalyst version.

=head1 TRANSLATIONS

This plugin has been translated to the folowing languages (alphabetic order):

=over 4

=item Arabic  (AZAWAWI)

=item Brazilian Portuguese (GARU)

=item Chinese (Traditional) (BLUET)

=item Dutch (DDN)

=item French (JQUELIN)

=item German (SEWI)

=item Japanese (ISHIGAKI)

=item Polish (THEREK)

=item Russian (SHARIFULN)

=item Spanish (BRUNOV)

=back

Many thanks to all contributors!

Feel free to help if you find any of the translations need improvement/updating, or if you can add more languages to this list. Thanks!

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-catalyst at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Catalyst>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Catalyst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Catalyst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Catalyst/>

=back


=head1 SEE ALSO

L<Catalyst>, L<Padre>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
