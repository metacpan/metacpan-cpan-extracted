package Padre::Plugin::Plack;
BEGIN {
  $Padre::Plugin::Plack::VERSION = '1.200';
}

# ABSTRACT: PSGI/Plack plugin for Padre

use warnings;
use strict;
use base 'Padre::Plugin';
use utf8;

use Padre::Util ('_T');
use Padre::Logger;


sub padre_interfaces {
    'Padre::Plugin'     => 0.43,
      'Padre::Document' => 0.57;
}


sub registered_documents {
    'application/x-psgi' => 'Padre::Document::PSGI';
}

# Static cache for the dot-psgi examples (read off disk)
my %PSGI_EXAMPLES;


sub menu_plugins {
    my $self = shift;
    my $main = shift;

    my $menu = Wx::Menu->new;

    my $app_menu = Wx::Menu->new;
    $menu->Append( -1, _T('New PSGI App'), $app_menu );

    for my $basename ( sort keys %PSGI_EXAMPLES ) {
        Wx::Event::EVT_MENU(
            $main,
            $app_menu->Append( -1, $basename ),
            sub {
                $self->on_app_load( $PSGI_EXAMPLES{$basename} );
                return;
            },
        );
    }

    my $docs_menu = Wx::Menu->new;
    $menu->Append( -1, _T('Online References'), $docs_menu );

    Wx::Event::EVT_MENU(
        $main,
        $docs_menu->Append( -1, 'plackperl.org' ),
        sub {
            Padre::Wx::launch_browser('http://plackperl.org');
        }
    );

    Wx::Event::EVT_MENU(
        $main,
        $docs_menu->Append( -1, _T('Plack Advent Calendar') ),
        sub {
            Padre::Wx::launch_browser('http://advent.plackperl.org');
        },
    );

    Wx::Event::EVT_MENU( $main, $menu->Append( -1, _T('About') ), sub { $self->on_about_load }, );

    # Return it and the label for our plug-in
    return ( $self->plugin_name => $menu );
}


sub on_app_load {
    my $self = shift;
    my $file = shift;

    my $main = $self->main;

    # Slurp in the new app content from the template file
    my $template = Padre::Util::slurp($file);
    unless ($template) {

        # Rare failure, no need to translate
        $self->main->error( sprintf( _T('Failed to open template file %s'), $file ) );
        return;
    }

    # Create new document editor tab
    $main->new_document_from_string( $$template, 'application/x-psgi' );
    my $editor = $main->current->editor;
    my $doc    = $editor->{Document};

    # N.B. It used to be necessary to deliberately use application/x-perl mime type and then rebless as
    # a hack to make syntax highlighting work off the bat, but it seems to work now
    #    $doc->set_mimetype('application/x-psgi');
    #    $doc->rebless;
    $self->on_doc_load($doc);

    # The tab exists, so trigger set_tab_icon
    $doc->set_tab_icon;
}


sub is_psgi_doc {
    my $self = shift;
    my $doc  = shift;

    return $doc->isa('Padre::Document::PSGI') && $doc->can('mimetype') && $doc->mimetype eq 'application/x-psgi';
}


sub editor_enable {
    my $self   = shift;
    my $editor = shift;
    my $doc    = shift;

    # Only respond to event on psgi docs
    return unless $self->is_psgi_doc($doc);

    TRACE('->editor_enable') if DEBUG;

    $self->on_doc_load($doc);

    # Deliberately don't trigger Padre::Document::PSGI::set_tab_icon here because the tab doesn't exist yet
    # (it gets triggered by our tomfoolery in Padre::Document::PSGI::restore_cursor_position)
}


sub editor_changed {
    my $self = shift;

    my $main   = $self->main            or return;
    my $editor = $main->current->editor or return;
    my $doc    = $editor->{Document}    or return;

    # Only respond to event on psgi docs
    return unless $self->is_psgi_doc($doc);

    TRACE('->editor_changed') if DEBUG;

    ## TODO: add check that doc is now selected (for safety)..
    $self->on_panel_load($doc);
}


sub on_panel_load {
    my $self = shift;
    my $doc  = shift;

    if ( !$doc->panel ) {
        TRACE('->on_panel_load creating panel') if DEBUG;
        require Padre::Plugin::Plack::Panel;
        $doc->panel( Padre::Plugin::Plack::Panel->new($doc) );
    }

    # Show the panel, and pass an onclose callback
    Padre::Current->main->bottom->show(
        $doc->panel,
        sub {

            # Closing the panel causes bad things to happen
            $self->main->error(
                _T(q{'Sorry Dave, I can't do that - you need to close the corresponding file tab to close this panel})
            );

            # We can't actually cancel the close, so re-create it
            $self->plackdown($doc);
            $doc->panel(undef);
            $self->on_panel_load($doc);
        }
    );
    Padre::Current->main->refresh;
}


sub on_panel_close {
    my $self = shift;
    my $doc  = shift;

    return unless $doc && $doc->panel;

    if ( my $panel = $doc->panel ) {
        $self->plackdown($doc);
        $self->main->bottom->hide($panel);
        $doc->panel(undef);
    }
}


sub on_doc_load {
    my $self = shift;
    my $doc  = shift;

    TRACE('->on_doc_load') if DEBUG;

    if ( !$doc->isa('Padre::Document::PSGI') ) {
        $self->error( sprintf( _T('Expected a PSGI document, but instead got: %s'), ref $doc ) );
        return;
    }

    # Set the icon path, but don't actually trigger set_icon_tab() just yet
    $doc->icon_path( $self->plugin_directory_share . "/icons/16x16/logo.png" );
    $doc->plugin($self);

    # Trigger the Document's general setup event
    $doc->on_load;

    # Show the panel
    $self->on_panel_load($doc);
}


sub on_doc_close {
    my $self = shift;
    my $doc  = shift;

    TRACE('->on_doc_close') if DEBUG;

    if ( !$doc->isa('Padre::Document::PSGI') ) {
        $self->error( sprintf( _T('Expected a PSGI document, but instead got: %s'), ref $doc ) );
        return;
    }

    $self->on_panel_close($doc);
}


sub on_about_load {
    require Plack;
    require Class::Unload;
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre::Plugin::Plack");
    $about->SetDescription( _T('PSGI/Plack support for Padre') . "\n"
          . _T('by') . "\n"
          . 'Patrick Donelan (pat@patspam.com)' . "\n\n"
          . _T('This system is running Plack version')
          . " $Plack::VERSION\n"
          . 'http://plackperl.org' );
    $about->SetVersion($Padre::Plugin::Plack::VERSION);
    Class::Unload->unload('Plack');

    Wx::AboutBox($about);
    return;
}


sub load_dot_psgi_examples {
    my $self = shift;

    require File::Find::Rule;
    %PSGI_EXAMPLES =
      map { File::Basename::basename($_) => $_ }
      File::Find::Rule->file()->name('*.psgi')->in( $self->plugin_directory_share . '/dot-psgi' );
}




sub plugin_enable {
    my $self = shift;

    $self->load_dot_psgi_examples;
}


sub plugin_disable {
    my $self = shift;

    # TODO: Loop over all docs and turn off their psgi goodies: panel, stop server, etc..

    # cleanup loaded classes
    require Class::Unload;
    Class::Unload->unload('Padre::Document::PSGI');
    Class::Unload->unload('Padre::Plugin::Plack::Panel');
}


sub plackup {
    my $self = shift;
    my $doc  = shift;

    return unless $doc;
    TRACE('->plackup') if DEBUG;

    my $main     = $self->main;
    my $filename = $doc->filename;

    if ( !$filename ) {
        $main->on_save;
        $filename = $doc->filename;
        return unless $filename;
    }

    my $pwd = Cwd::cwd();
    chdir $doc->dirname;

    # Server ("Let plackup guess" means leave as unspecified)
    my $server = $doc->panel->{server}->GetValue;
    $server = $server eq _T('Let plackup guess') ? '' : "-s $server";

    # Port (required for browser url)
    my $port = $doc->panel->{port}->GetValue || 5000;
    $port = "-p $port";

    my $restart = $doc->panel->{restart}->GetValue ? '-r' : '';
    my $plackup_options = $doc->panel->{plackup_options}->GetValue;

    require File::Which;
    my $plackup = File::Which::which('plackup');
    if ( !$plackup ) {
        $main->error( _T('plackup command not found, please check your Plack installation and $PATH') );
        return;
    }

    my $cmd = qq{$plackup $port $restart $server $plackup_options "$filename"};
    TRACE("->plackup $cmd") if DEBUG;
    $self->run_command( $doc, $cmd );

    # restore previous dir
    chdir $pwd;
}


sub plackdown {
    my $self = shift;
    my $doc  = shift;

    return unless $doc;

    TRACE('->plackdown') if DEBUG;

    my $process = $doc->process;
    return unless $process;

    # sanity check
    if ( !$process->IsAlive ) {
        TRACE('->plackdown process was dead but not undef, strange') if DEBUG;
        $doc->process(undef);
    }

    my $processid = $process->GetProcessId();
    my $panel     = $doc->panel;

    require Proc::Killfam;
    my @signals = qw(INT TERM QUIT KILL STOP);
    for my $sig (@signals) {
        TRACE("Sending $sig to PID: $processid") if DEBUG;
        my $signalled = Proc::Killfam::killfam( $sig, $processid );

        if ( $panel->{restart}->GetValue ) {

            # with auto-restart, we expect 3 processes
            return if $signalled > 1;
        }
        else {

            # otherwise, just one
            return if $signalled > 0;
        }
    }

    $panel->output->AppendText( "\n" . "Process PID $processid did not respond, you may need to kill it manually\n" );
}


sub run_command {
    my ( $self, $doc, $command ) = (@_);

    my $panel = $doc->panel;

    # clear the panel
    $panel->output->Remove( 0, $panel->output->GetLastPosition );

    # If this is the first time a command has been run, set up the ProcessStream bindings.
    unless ( $panel->{bound} ) {
        TRACE(' setting up ProcessStream bindings') if DEBUG;

        require Wx::Perl::ProcessStream;
        if ( $Wx::Perl::ProcessStream::VERSION < .20 ) {
            $self->main->error(
                sprintf(
                    _T(
                            'Wx::Perl::ProcessStream is version %s'
                          . ' which is known to cause problems. Get at least 0.20 by typing'
                          . "\ncpan Wx::Perl::ProcessStream"
                    ),
                    $Wx::Perl::ProcessStream::VERSION
                )
            );
            return 1;
        }

        Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT(
            $panel->output,
            sub {
                $_[1]->Skip(1);
                my $outpanel = $_[0];
                $outpanel->style_good;
                $outpanel->AppendText( $_[1]->GetLine . "\n" );
                return;
            },
        );
        Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDERR(
            $panel->output,
            sub {
                $_[1]->Skip(1);
                my $outpanel = $_[0];
                $outpanel->style_neutral;
                $outpanel->AppendText( $_[1]->GetLine . "\n" );

                return;
            },
        );
        Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT(
            $panel->output,
            sub {
                $_[1]->Skip(1);
                $_[1]->GetProcess->Destroy;

                TRACE(' PROCESS_STREAM_EXIT') if DEBUG;

                my $outpanel = $_[0];
                $outpanel->style_neutral;
                $outpanel->AppendText("\nProcess terminated\n");
                $panel->set_as_stopped;

                $doc->process(undef);
            },
        );
        $panel->{bound} = 1;
    }

    # Start the command
    my $process = Wx::Perl::ProcessStream::Process->new( $command, "Run $command", $panel->output );
    $doc->process( $process->Run );

    # Check if we started the process or not
    if ( $doc->process ) {
        $panel->set_as_started;

    }
    else {

        # Failed to start the command. Clean up.
        $panel->set_as_stopped;    # should already be stopped, but just in case
        Wx::MessageBox( sprintf( _T("Failed to start server via '%s'"), $command ), _T("Error"), Wx::wxOK, $self );
    }

    return;
}


sub build_panel {
    my $self  = shift;
    my $doc   = shift;
    my $panel = shift;

    require Scalar::Util;
    $panel->{doc} = $doc;
    Scalar::Util::weaken( $panel->{doc} );

    # main container
    my $box = Wx::BoxSizer->new(Wx::wxVERTICAL);

    # top box, holding buttons, icons and checkboxes
    my $top_box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);

    # LED showing process status
    $panel->{led} = Wx::StaticBitmap->new( $panel, -1, Wx::wxNullBitmap );
    $top_box->Add( $panel->{led}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Servers
    my @servers = sort qw(
      Standalone
      Apache1
      Apache2
      Apache2::RegistryAnyEvent
      AnyEvent::HTTPD
      AnyEvent::ReverseHTTP
      AnyEvent::SCGI
      AnyEvent::Server::Starter
      CGI
      Corona
      FCGI
      FCGI::Engine
      HTTP::Server::PSGI
      HTTP::Server::Simple
      Server::Simple
      SCGI
      Starman
      Starlet
      Twiggy
      POE
      ReverseHTTP
    );
    unshift @servers, _T('Let plackup guess');
    $top_box->AddSpacer(5);
    $top_box->Add( Wx::StaticText->new( $panel, -1, _T('Server') . ':' ), 0, Wx::wxALIGN_CENTER_VERTICAL );
    $panel->{server} =
      Wx::ComboBox->new( $panel, -1, 'Standalone', Wx::wxDefaultPosition, Wx::wxDefaultSize, [@servers],
        Wx::wxCB_DROPDOWN );
    $top_box->Add( $panel->{server}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Port
    $top_box->AddSpacer(5);
    $top_box->Add( Wx::StaticText->new( $panel, -1, _T('Port') . ':' ), 0, Wx::wxALIGN_CENTER_VERTICAL );
    $panel->{port} = Wx::TextCtrl->new( $panel, -1, '5000' );
    $top_box->Add( $panel->{port}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Plackup Options
    $top_box->AddSpacer(5);
    $top_box->Add( Wx::StaticText->new( $panel, -1, _T('Options') . ':' ), 0, Wx::wxALIGN_CENTER_VERTICAL );
    $panel->{plackup_options} = Wx::TextCtrl->new( $panel, -1, '' );
    $top_box->Add( $panel->{plackup_options}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Restart
    $top_box->AddSpacer(5);
    $panel->{restart} = Wx::CheckBox->new( $panel, -1, _T('Auto-Restart') );
    $panel->{restart}->SetValue(1);
    $top_box->Add( $panel->{restart}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Start/stop button
    $top_box->AddSpacer(5);
    $panel->{start_stop} = Wx::Button->new( $panel, -1, '' );
    Wx::Event::EVT_BUTTON(
        $panel,
        $panel->{start_stop},
        sub {
            my $panel = shift;

            # Trigger plackup/down
            if ( $panel->{start_stop}->GetLabel eq _T('Start') ) {
                $doc->plugin->plackup($doc);
            }
            else {
                $doc->plugin->plackdown($doc);
            }
        },
    );
    $top_box->Add( $panel->{start_stop}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # Browser
    $top_box->AddSpacer(5);
    $panel->{browse} = Wx::Button->new( $panel, -1, _T('View in Browser') );
    Wx::Event::EVT_BUTTON(
        $panel,
        $panel->{browse},
        sub {
            my $panel = shift;
            my $port = $panel->{port}->GetValue || 5000;
            Padre::Wx::launch_browser("http://0:$port");
        },
    );
    $top_box->Add( $panel->{browse}, 0, Wx::wxALIGN_CENTER_VERTICAL );

    # finishing up the top_box
    $box->Add( $top_box, 0, Wx::wxALIGN_LEFT | Wx::wxALIGN_CENTER_VERTICAL );

    # output panel for server
    require Padre::Wx::Output;
    my $output = Padre::Wx::Output->new( $self->main, $panel );

    $box->Add( $output, 1, Wx::wxGROW );

    # wrapping it up
    $panel->SetSizer($box);

    # holding on to some objects we'll need to manipulate later on
    $panel->{output} = $output;

    $panel->set_as_stopped;
}


1;


=pod

=head1 NAME

Padre::Plugin::Plack - PSGI/Plack plugin for Padre

=head1 VERSION

version 1.200

=head1 SYNOPSIS

    # cpan install Padre::Plugin::Plack;
    # Then enable it via L<Padre>, The Perl IDE:
    # Padre > Plugins > Plugin Manager > Plack > enable

=head1 DESCRIPTION

As the name suggests, Padre::Plugin::Plack adds L<Plack> awareness to L<Padre>.

With the plugin installed, opening *.psgi files causes some special things to
happen.

PSGI files are really just ordinary Perl files, so Padre does its normal Perl
lexing/syntax highlighting magic on them, but the real fun starts with the
Plack-specific features that appear in the per-file graphical L<plackup> control
panel that shows up.

The panel lets you run your web app in a Plack server at the click of a button,
view server output, configure plackup options and launch a web browser on the
appropriate port.

The great thing about Plack/PSGI is that unlike my previous plugin
(L<Padre::Plugin::WebGUI>) which was specific to a single web app (albeit a big one),
this plugin can be used for any web app built in a web framework that supports
Plack (L<Catalyst>, L<CGI::Application>, L<HTTP::Engine>, etc..). This is the same
motivating factor that excites L<Plack::Middleware> authors.

The plugin turns on plackup’s C<--reload> option by default, which conveniently
causes the plack server to reload every time you modify your source files in Padre.
This makes for quite a nice, if somewhat minimal "Plack IDE" experience
(this is version 0.01 after all).

The plugin integrates all of the L<Plack> example "dot-psgi”"files as templates
that can be used to create different types of Plack apps straight from the GUI menu.

The pre-populated list of Plack servers and the simple start/stop button makes for
a nice way of exploring the Plack server ecosystem. You can use the other panel
options to enter a specific port to run on, toggle auto-start mode and pass additional
options to plackup (options that start with C<--> are passed through to the backend
server).

The output panel is similar to the output panel that Padre normally displays when you
execute Perl files, except that you get one panel per .psgi file meaning that you can
run multiple plack servers simultaneously and independently view their output.
The appropriate panel is automatically selected when you click on the corresponding
file tab, and running processes are stopped when you close the tab.

It should be really easy to turn Padre::Plugin::Plack into new plugins that involve the
same basic ingredients, namely a file extension and an external command for running those
files, with a per-file panel for command options and output. So I encourage anyone who has
a similar plugin in mind to steal liberally from Padre::Plugin::Plack (as I did from
L<Padre::Plugin::Catalyst> - thanks garu++).
Ruby Rack support comes to mind as a trivial example.

Make Padre your domain-specific IDE today :)

Blog post with screenshots: L<http://blog.patspam.com/2009/padrepluginplack>

=head1 METHODS

=head2 padre_interfaces

Declare the Padre interfaces this plugin uses

=head2 registered_documents

Declare ourselves as the handler for .psgi files

=head2 menu_plugins

Create the plugin menu

=head2 on_app_load

Called when Padre loads

=head2 is_psgi_doc

=head2 editor_enable

=head2 editor_changed

=head2 on_panel_load

=head2 on_panel_close

=head2 on_doc_load

Note that the new tab may or may not exist at this point
When triggered by user opening a new file (e.g. from L<on_app_load>), tab does not exist yet
Whereas, when triggered by user creating new app from template, tab exists

=head2 on_doc_close

=head2 on_about_load

=head2 load_dot_psgi_examples

=head2 plugin_enable

=head2 plugin_enable

=head2 plackup

=head2 plackdown

=head2 run_command

=head2 build_panel

This method belonds in Padre::Plugin::Plack::Panel but we keep it here
to speed up the dev edit-reload cycle

=head2 TRACE

=head1 CONTRIBUTORS

=encoding utf8

=over 4

=item *

Gábor Szabó - גאבור סבו (SZABGAB) E<lt>szabgab@gmail.comE<gt>

=back

=head1 TRANSLATORS

Big thanks to all the wonderful translators!

=over 4

=item *

French - Jerome Quelin (jquelin) E<lt>jquelin@cpan.orgE<gt>

=item *

Dutch - Dirk De Nijs (ddn123456) E<lt>DIRKDN@cpan.orgE<gt>

=item *

Brazilian Portuguese - Breno G. de Oliveira (GARU) E<lt>garu@cpan.orgE<gt>

=item *

Arabic - أحمد محمد زواوي Ahmad M. Zawawi (azawawi) E<lt>ahmad.zawawi@gmail.comE<gt>

=item *

Turkish - Burak Gürsoy (burak) E<lt>burak@cpan.orgE<gt>

=item *

Italian - Simone Blandino (sblandin)

=back

=head1 SEE ALSO

L<Plack>, L<Padre>

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

