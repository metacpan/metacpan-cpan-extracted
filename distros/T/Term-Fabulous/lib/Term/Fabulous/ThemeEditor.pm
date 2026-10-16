package Term::Fabulous::ThemeEditor;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::ThemeEditor :strict(params) {
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_fixed sizing_grow sizing_percent CLAY_TOP_TO_BOTTOM);
	use Cwd qw(abs_path getcwd);
	use Encode qw(decode encode);
	use Feature::Compat::Try;
	use File::Basename qw(basename dirname);
	use File::Spec;
	use IO::Async::Loop;
	use IO::Async::Signal;
	use IO::Async::OS;
	use IO::Async::Timer::Countdown;
	use List::Util qw(any first max min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Commands;
	use Term::Fabulous::Editor;
	use Term::Fabulous::Theme;
	use Term::Fabulous::Theme::Document;
	use Term::Fabulous::ThemeEditor::Form;
	use Term::Fabulous::ThemeEditor::Preview;
	use Term::Fabulous::ThemeEditor::Tab;
	use Term::Fabulous::ThemeEditor::UI;
	use Term::Fabulous::ThemeEditor::ValueDialog;
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::DocumentTabs;
	use Term::Fabulous::Widget::Dropdown;
	use Term::Fabulous::Widget::FileDialog;
	use Term::Fabulous::Widget::KeyReference;
	use Term::Fabulous::Widget::MenuBar;
	use Term::Fabulous::Widget::Prompt;
	use Term::Fabulous::Widget::RichText;
	use Term::Fabulous::Widget::ScrollBox;
	use Term::Fabulous::Widget::SegmentedControl;
	use Term::Fabulous::Widget::StatusBar;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	# How long the text must rest before it is parsed again, in seconds.
	use constant PARSE_DELAY => 0.15;

	# What the open and save dialogs list.
	use constant THEME_FILTERS => [ [ 'Theme files' => '*.kdl' ], [ 'All files' => '*' ] ];

	use constant WATCHED_SIGNALS => qw(TERM INT HUP);

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	field $files     :param = [];
	field $ui_theme  :param = 'dark';
	field $preview   :param = undef;    # a widget, or code that returns one
	field $directory :param = undef;
	field $terminal  :param = undef;
	field $width     :param = 80;
	field $height    :param = 24;

	# ---------------------------------------------------------------------
	# State
	# ---------------------------------------------------------------------

	field $ui :reader;
	field @tabs;
	field $active;    # index of the shown tab, undef when none is open
	field $untitled_count = 0;
	field $quitting       = 0;
	field $parse_timer;
	field @recovered;    # the recovery files the last run wrote
	field @signal_watchers;
	field %signals_before;
	field $signalled = 0;

	field $menu;
	field $strip;
	field $gallery;    # the Term::Fabulous::ThemeEditor::Preview, or undef for a custom preview
	field $preview_root;
	field $preview_pane;
	field $preview_title;
	field $settings_pane;
	field $settings_title;
	field $mode_switch;
	field $content;    # holds the form, the text or the welcome text
	field $form :reader;
	field $text_box;
	field $errors_text;
	field $welcome;
	field $status :reader;
	field $commands  = Term::Fabulous::Commands->new;
	field $find_text = '';

	ADJUST {
		die "Term::Fabulous::ThemeEditor: files must be an array reference of file names, got " . describe($files) unless ref $files eq 'ARRAY' && !grep { !defined || ref || !length } @$files;
		$directory //= getcwd();
		die "Term::Fabulous::ThemeEditor: directory '$directory' is not a directory" unless -d $directory;
		$self->_define_commands;
		$self->_build_screen;
		$self->open_file($_) foreach @$files;
		$status->message( sprintf 'Opened %d themes. F1 lists every key; F10 or Alt with an underlined letter opens a menu.', scalar @tabs ) if @$files > 1;
		$self->new_theme unless @tabs;
		$self->_show_active;
		$self->_focus_settings;
	}

	# ---------------------------------------------------------------------
	# Commands: every action, with its menu entry and keys
	# ---------------------------------------------------------------------

	method _command ( $id, %definition ) {
		$commands->add( { id => $id, %definition } );
		return;
	}

	method _define_commands () {
		weaken( my $editor = $self );
		my $has_tab  = sub { defined $editor->active_tab };
		my $in_form  = sub { defined $editor->active_tab && $editor->active_tab->mode eq 'form' };
		my $writable = sub { $in_form->()                && !$editor->active_tab->document->has_syntax_error };

		$self->_command( new     => label => 'New theme...', keys => ['Ctrl+N'], run => sub { $editor->_ask_new_theme } );
		$self->_command( open    => label => 'Open...',      keys => ['Ctrl+O'], run => sub { $editor->_ask_open } );
		$self->_command( save    => label => 'Save',         keys => ['Ctrl+S'], run => sub { $editor->_save },    enabled => $has_tab );
		$self->_command( save_as => label => 'Save as...',   keys => ['Alt+S'],  run => sub { $editor->_save_as }, enabled => $has_tab );
		$self->_command(
			save_all => label => 'Save all',
			keys     => [],
			run      => sub { $editor->_save_all },
			enabled  => sub {
				any { $_->is_modified } @tabs;
			}
		);
		$self->_command(
			revert  => label => 'Revert to saved', keys => ['Ctrl+R'], run => sub { $editor->_revert },
			enabled => sub { defined $editor->active_tab && defined $editor->active_tab->path && -f $editor->active_tab->path }
		);
		$self->_command( duplicate => label => 'Duplicate as new theme', keys => [],         run => sub { $editor->_duplicate }, enabled => $has_tab );
		$self->_command( close     => label => 'Close tab',              keys => ['Ctrl+W'], run => sub { $editor->close_tab },  enabled => $has_tab );
		$self->_command( quit      => label => 'Quit',                   keys => ['Ctrl+Q'], run => sub { $editor->_quit } );

		$self->_command( undo       => label => 'Undo', keys => ['Ctrl+Z'], run => sub { $editor->_undo }, enabled => sub { defined $editor->active_tab && $editor->active_tab->can_undo } );
		$self->_command( redo       => label => 'Redo', keys => ['Ctrl+Y'], run => sub { $editor->_redo }, enabled => sub { defined $editor->active_tab && $editor->active_tab->can_redo } );
		$self->_command( cut        => label => 'Cut',                      keys => ['Ctrl+X'], run => sub { $editor->_cut },                   enabled => $has_tab );
		$self->_command( copy       => label => 'Copy',                     keys => ['Ctrl+C'], run => sub { $editor->_copy },                  enabled => $has_tab );
		$self->_command( paste      => label => 'Paste',                    keys => ['Ctrl+V'], run => sub { $editor->_paste },                 enabled => $has_tab );
		$self->_command( paste_keys => label => 'Paste at the copied keys', keys => ['Alt+P'],  run => sub { $editor->_paste( at_keys => 1 ) }, enabled => $writable );
		$self->_command( edit      => label => 'Edit value...',    keys => ['Enter'],  run => sub { $editor->_edit_current },  enabled => sub { $writable->() && defined $editor->form->current_key } );
		$self->_command( reset     => label => 'Reset to default', keys => ['Delete'], run => sub { $editor->_reset_current }, enabled => $writable );
		$self->_command( find      => label => 'Find...',          keys => ['Ctrl+F'], run => sub { $editor->_find },          enabled => $has_tab );
		$self->_command( find_next => label => 'Find next',        keys => ['F3'],     run => sub { $editor->_find_next },     enabled => sub { defined $editor->active_tab && length $find_text } );
		$self->_command(
			next_error => label => 'Go to the next error', keys => ['F8'], run => sub { $editor->_next_error },
			enabled    => sub { defined $editor->active_tab && !$editor->active_tab->document->is_valid }
		);

		$self->_command( toggle_mode => label => 'Form or text', keys => ['F2'], run => sub { $editor->_toggle_mode }, enabled => $has_tab );
		$self->_command(
			switch_pane => label => 'Preview or settings', keys => ['F6'], run => sub { $editor->_switch_pane },
			enabled     => sub { defined $editor->active_tab && $editor->_preview_shown }
		);
		$self->_command( toggle_preview => label => 'Show or hide the preview', keys => ['F7'],           run => sub { $editor->_toggle_preview } );
		$self->_command( only_set       => label => 'Only set settings',        keys => ['Alt+L'],        run => sub { $editor->_toggle_only_set },          enabled => $in_form );
		$self->_command( open_all       => label => 'Open all sections',        keys => [],               run => sub { $editor->form->list->expand_all },    enabled => $in_form );
		$self->_command( close_all      => label => 'Close all sections',       keys => [],               run => sub { $editor->form->list->collapse_all },  enabled => $in_form );
		$self->_command( previous_tab   => label => 'Previous tab',             keys => ['Alt+PageUp'],   run => sub { $editor->select_tab( $active - 1 ) }, enabled => sub { @tabs > 1 } );
		$self->_command( next_tab       => label => 'Next tab',                 keys => ['Alt+PageDown'], run => sub { $editor->select_tab( $active + 1 ) }, enabled => sub { @tabs > 1 } );

		$self->_command( rename         => label => 'Rename theme...',      keys => [], run => sub { $editor->_edit_key('theme.name') },    enabled => $has_tab );
		$self->_command( rebase         => label => 'Change base theme...', keys => [], run => sub { $editor->_edit_key('theme.extends') }, enabled => $has_tab );
		$self->_command( add_variant    => label => 'Add variant...',       keys => [], run => sub { $editor->_ask_add_variant },           enabled => $writable );
		$self->_command( remove_variant => label => 'Remove variant',   keys => [], run => sub { $editor->_remove_variant },  enabled => sub { $writable->() && defined $editor->_current_variant } );
		$self->_command( reset_section  => label => 'Reset section...', keys => [], run => sub { $editor->_reset_section },   enabled => sub { $writable->() && defined $editor->form->current } );
		$self->_command( reset_theme    => label => 'Reset whole theme...', keys => [], run => sub { $editor->_reset_theme }, enabled => $writable );

		$self->_command( keys  => label => 'Key reference', keys => ['F1'], run => sub { $editor->_show_keys } );
		$self->_command( about => label => 'About',         keys => [],     run => sub { $editor->_show_about } );
		return;
	}

	method _menus () {
		return [
			{ title => 'File',  items => [qw(new open - save save_as save_all revert - duplicate - close quit)] },
			{ title => 'Edit',  items => [qw(undo redo - cut copy paste paste_keys - edit reset - find find_next next_error)] },
			{ title => 'View',  items => [qw(toggle_mode switch_pane toggle_preview - only_set open_all close_all - previous_tab next_tab)] },
			{ title => 'Theme', items => [qw(rename rebase - add_variant remove_variant - reset_section reset_theme)] },
			{ title => 'Help',  items => [qw(keys about)] },
		];
	}

	method run_command ($id) {
		return $commands->command($id)->run;
	}

	# Every command: its id, its label in the menus and its keys.
	method commands () {
		return map { { id => $_->id, label => $_->label =~ s/\.\.\.\z//r, keys => [ $_->keys ] } } $commands->commands;
	}

	method command_enabled ($id) {
		return $commands->command($id)->is_enabled;
	}

	# ---------------------------------------------------------------------
	# The screen
	# ---------------------------------------------------------------------

	method _build_screen () {
		weaken( my $editor = $self );
		my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );

		$menu = Term::Fabulous::Widget::MenuBar->new(
			commands => $commands,
			menus    => $self->_menus,
			caption  => 'Term::Fabulous theme editor',
			layout   => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } },
		);
		$strip = Term::Fabulous::Widget::DocumentTabs->new(
			tabs   => sub { $editor->_tab_summaries },
			layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } },
		);
		$strip->on( Select   => sub ($event) { $editor->select_tab( $event->index ); return } );
		$strip->on( TabClose => sub ($event) { $editor->close_tab( $event->index );  return } );
		$strip->on( TabAdd   => sub ($event) { $editor->_ask_new_theme;              return } );

		# The preview pane: the editor draws its frame and title, the preview
		# inside it draws in the theme being edited.
		$preview_title = Term::Fabulous::Widget::RichText->new( text => 'Preview' );
		$preview_root  = $self->_preview_widget;
		$preview_pane  = $self->_pane( $preview_title, $preview_root );

		$settings_title = Term::Fabulous::Widget::RichText->new( text => 'Settings' );
		$mode_switch    = Term::Fabulous::Widget::SegmentedControl->new( options => [ [ Form => 'form' ], [ Text => 'text' ] ], value => 'form', can_focus => 0 );
		$mode_switch->on( Change => sub ($event) { $editor->set_mode( $event->value ); return Clay::UI::Enum::Result->CONTINUE } );
		my $title_box = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() } } );
		$title_box->add_child($settings_title);
		my $settings_head = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 } );
		$settings_head->add_child( $title_box, $mode_switch );
		$content       = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$settings_pane = $self->_pane( $settings_head, $content );

		$form = Term::Fabulous::ThemeEditor::Form->new(
			on_activate => sub ($key) { $editor->_edit_key($key) },
			on_cursor   => sub ($id) { $editor->_cursor_moved($id) },
		);
		$form->explain_with( sub ($row) { $editor->_explain($row) } );
		$text_box    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$errors_text = Term::Fabulous::Widget::RichText->new( text => '' );
		$welcome     = Term::Fabulous::Widget::RichText->new(
			markup => "No theme is open.\n\n[bold]Ctrl+N[/] makes a new theme, [bold]Ctrl+O[/] opens a theme file, [bold]F1[/] lists every key, [bold]Ctrl+Q[/] quits.",
		);

		my $workspace = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$workspace->add_child( $preview_pane, $settings_pane );

		$status = Term::Fabulous::Widget::StatusBar->new( parts => sub { $editor->_status_info }, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } );
		$root->add_child( $menu, $strip, $workspace, $status );

		$ui = Term::Fabulous::ThemeEditor::UI->new(
			root           => $root,
			theme          => $ui_theme,
			stop_on_ctrl_c => 0,
			width          => $width,
			height         => $height,
			( defined $terminal ? ( terminal => $terminal ) : () ),
		);
		$ui->add_preview_root($preview_root);
		$root->on( KeyPress => sub ($event) { return $editor->_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
		$root->on( OnFocus  => sub ($event) { $editor->_focus_moved; return Clay::UI::Enum::Result->CONTINUE } );
		$root->on(
			Start => sub ($event) {
				$editor->status->message('The terminal is narrow: F7 hides the preview, so the settings get the whole width.') if $event->width < 100;
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
		$root->on(
			MouseMove => sub ($event) {
				my $list = $editor->form->list;
				$list->hover(undef) unless blessed $event->target && $list->contains( $event->target );
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
		$status->message('Welcome. F1 lists every key; F10 or Alt with an underlined letter opens a menu.');
		return;
	}

	# Hides the preview, so the settings take the whole width (on a narrow
	# terminal), or shows it again.
	method _preview_shown () {
		return $settings_pane->parent->has_child($preview_pane) ? 1 : 0;
	}

	method _toggle_preview () {
		my $workspace = $settings_pane->parent;
		my $shown     = $workspace->has_child($preview_pane);
		if ($shown) {
			my $focused = $ui->interaction->get_focused_widget;
			$self->_focus_settings if defined $focused && $preview_pane->contains($focused);
			$workspace->remove_child($preview_pane);
		}
		else {
			$workspace->insert_children( 0, $preview_pane );
		}
		$settings_pane->layout( { %{ $settings_pane->layout }, sizing => { width => $shown ? sizing_grow() : sizing_percent(0.5), height => sizing_grow() } } );
		$status->message( $shown ? 'The preview is hidden; F7 shows it again.' : 'The preview is back.' );
		return;
	}

	# A framed part of the workspace.
	method _pane ( $head, $body ) {
		my $pane = Term::Fabulous::Widget::Box->new(
			bordered => 1,
			layout   => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_percent(0.5), height => sizing_grow() }, padding => { left => 1, right => 1 } },
		);
		$pane->add_child( $head, $body );
		return $pane;
	}

	# The preview: the gallery, or the program's own widgets.
	method _preview_widget () {
		my $widget = ref $preview eq 'CODE' ? $preview->($self) : $preview;
		if ( !defined $widget ) {
			$gallery = Term::Fabulous::ThemeEditor::Preview->new;
			return $gallery;
		}
		die "Term::Fabulous::ThemeEditor: preview must be a Term::Fabulous::Widget or code that returns one, got " . describe($widget)
			unless blessed $widget && $widget->isa('Term::Fabulous::Widget');

		# A scroll box in both directions keeps any content inside the pane.
		my $holder = Term::Fabulous::Widget::ScrollBox->new(
			id         => 'theme-editor-custom-preview',
			horizontal => 1,
			layout     => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$holder->add_child($widget);
		weaken( my $weak_holder = $holder );
		$holder->on( KeyPress => sub ($event) { return _scroll_by_key( $weak_holder, $event ) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
		return $holder;
	}

	# PageUp, PageDown, Ctrl+Home and Ctrl+End scroll a scroll box when the
	# focused widget in it does not use them.
	sub _scroll_by_key ( $box, $event ) {
		my %page = ( PageUp => 1, PageDown => -1 );
		my $name = $event->main_key_name // return 0;
		return 0 unless exists $page{$name} || $name eq 'Ctrl+Home' || $name eq 'Ctrl+End';
		my $ui     = $box->ui                // return 0;
		my $view   = $ui->bounding_box($box) // return 0;
		my $state  = $ui->scroll_state($box) // return 0;
		my $lowest = min( 0, $view->{height} - ( $state->{content}{height} // 0 ) );
		my $target = $name eq 'Ctrl+Home' ? 0 : $name eq 'Ctrl+End' ? $lowest : ( $state->{position}{y} // 0 ) + $page{$name} * ( $view->{height} - 1 );
		$ui->scroll_to( $box, { y => max( $lowest, min( 0, $target ) ) } );
		return 1;
	}

	# ---------------------------------------------------------------------
	# Running
	# ---------------------------------------------------------------------

	# Runs the editor until the user quits. A signal (TERM, INT, HUP) ends
	# it too; the text of themes with unsaved changes is then written to
	# recovery files, which are listed on STDERR.
	method run () {
		( $quitting, $signalled ) = ( 0, 0 );
		$self->_watch_signals;
		try {
			$ui->run;
		}
		catch ($error) {
			$self->_stop_watching;
			die $error;
		}
		$self->_stop_watching;
		@recovered = $signalled && !$quitting ? $self->_recover : ();
		return $self;
	}

	# Term::Fabulous ends its loop (the process's IO::Async loop) on these
	# signals; the editor notes that one came, to keep the unsaved work.
	# The handlers the program had come back afterwards.
	method _watch_signals () {
		my $loop = IO::Async::Loop->new;
		weaken( my $editor = $self );
		my @signals = IO::Async::OS->HAVE_SIGNALS ? WATCHED_SIGNALS : ();    # IO::Async watches no signals on Windows
		%signals_before  = map { $_ => $SIG{$_} } @signals;
		@signal_watchers = map {
			IO::Async::Signal->new( name => $_, on_receipt => sub { $editor->_signalled } )
		} @signals;
		$loop->add($_) foreach @signal_watchers;
		return;
	}

	method _signalled () {
		$signalled = 1;
		return;
	}

	method recovered_files () {
		return @recovered;
	}

	method _stop_watching () {
		foreach my $notifier ( grep { defined } $parse_timer, @signal_watchers ) {
			$notifier->loop->remove($notifier) if defined $notifier->loop;
		}
		( $parse_timer, @signal_watchers ) = ();
		foreach my $name ( keys %signals_before ) {
			$SIG{$name} = $signals_before{$name} unless defined $SIG{$name};
		}
		%signals_before = ();
		return;
	}

	method _recover () {
		my @written;
		foreach my $tab ( grep { $_->is_modified } @tabs ) {
			try {
				push @written, $tab->write_recovery($directory);
			}
			catch ($error) {
				warn "Term::Fabulous::ThemeEditor: could not keep the unsaved text of " . $tab->title . ": $error";
			}
		}
		warn "Term::Fabulous::ThemeEditor: the editor was stopped with unsaved changes; they were written to:\n" . join( '', map { "  $_\n" } @written ) if @written;
		return @written;
	}

	# ---------------------------------------------------------------------
	# Tabs
	# ---------------------------------------------------------------------

	method tabs () {
		return @tabs;
	}

	method active_tab () {
		return defined $active ? $tabs[$active] : undef;
	}

	method _tab_summaries () {
		return map { { title => _title_of($_), modified => $_->is_modified, error => !$_->document->is_valid } } @tabs;
	}

	method _add_tab ($tab) {
		weaken( my $editor   = $self );
		weaken( my $weak_tab = $tab );
		$tab->area->on( Change => sub ($event) { $editor->_text_changed($weak_tab); return Clay::UI::Enum::Result->CONTINUE } );
		push @tabs, $tab;
		$self->select_tab($#tabs);
		return $tab;
	}

	# Opens a theme file in a new tab, or shows the tab it is open in. A
	# file that does not exist yet becomes a new theme that is saved there.
	method open_file ($path) {
		die "Term::Fabulous::ThemeEditor: open_file needs a file name, got " . describe($path) unless defined $path && !ref $path && length $path;
		die "Term::Fabulous::ThemeEditor: open_file needs the path as the file system has it (bytes), got a character string" if $path =~ /[^\x00-\xff]/;
		my $full     = abs_path($path) // $path;
		my $existing = first { defined $tabs[$_]->path && ( abs_path( $tabs[$_]->path ) // $tabs[$_]->path ) eq $full } 0 .. $#tabs;
		return $self->select_tab($existing) && $tabs[$existing] if defined $existing;
		if ( !-e $path ) {
			my ($name) = _decoded( basename($path) ) =~ /\A(.*?)(?:\.kdl)?\z/i;
			my $tab = $self->_add_tab( Term::Fabulous::ThemeEditor::Tab->new( path => $path, text => _template( $name, 'dark' ), modified => 1 ) );
			$status->message( $self->_shown_path($path) . ' does not exist yet; it is made when you save.' );
			return $tab;
		}
		my $document = Term::Fabulous::Theme::Document->read_file($path);
		my $tab      = $self->_add_tab( Term::Fabulous::ThemeEditor::Tab->new( path => $path, text => $document->text, mode => $document->is_valid ? 'form' : 'text' ) );
		$self->_show_active;
		my @errors = $tab->document->errors;
		my $shown  = $self->_shown_path($path);
		$status->message( @errors ? sprintf( 'Opened %s; it has %d error%s, shown in text mode.', $shown, scalar @errors, @errors == 1 ? '' : 's' ) : "Opened $shown.", @errors ? 'warning' : 'info' );
		return $tab;
	}

	# A path as the editor shows it: relative to the start directory when it
	# is inside it, and decoded.
	method _shown_path ($path) {
		my $full = abs_path($path)      // File::Spec->rel2abs($path);
		my $base = abs_path($directory) // $directory;
		return _decoded( index( $full, "$base/" ) == 0 ? substr( $full, length($base) + 1 ) : $full );
	}

	# Paths are bytes, as the file system has them; the editor shows them
	# as UTF-8 text, with a byte that is no UTF-8 as \xHH.
	sub _decoded ($bytes) {
		return decode( 'UTF-8', $bytes, Encode::FB_PERLQQ | Encode::LEAVE_SRC );
	}

	# The title of a tab as the editor shows it: its file's name decoded.
	sub _title_of ($tab) {
		return _decoded( $tab->title );
	}

	sub _template ( $name, $base ) {
		my $quoted = $name =~ s/(["\\])/\\$1/gr;
		return <<~"KDL";
			// A theme for Term::Fabulous; see Term::Fabulous::Theme. A program
			// loads it with Term::Fabulous::Theme->from_file.

			theme "$quoted" extends="$base"
			KDL
	}

	# A new theme in a new tab.
	method new_theme (%parameters) {
		my $number = ++$untitled_count;
		my $name   = $parameters{name}    // "untitled-$number";
		my $base   = $parameters{extends} // 'dark';
		die "Term::Fabulous::ThemeEditor: extends must be the name of a built-in theme, got " . describe($base) unless grep { $_ eq $base } Term::Fabulous::Theme::builtin_names();
		return $self->_add_tab( Term::Fabulous::ThemeEditor::Tab->new( untitled => $number, text => _template( $name, $base ) ) );
	}

	method select_tab ($index) {
		return 0 unless @tabs;
		$index %= @tabs;
		my $previous = $self->active_tab;
		$form->keep_state($previous) if defined $previous && ( !defined $active || $index != $active ) && $previous->mode eq 'form';
		$self->_sync($previous) if defined $previous;
		$active = $index;
		$self->_show_active;
		return 1;
	}

	method _remove_tab ($index) {
		my ($tab) = splice @tabs, $index, 1;
		if ( !@tabs ) {
			$active = undef;
		}
		elsif ( $active >= $index ) {
			$active = max( 0, $active - 1 );
		}
		$self->_show_active;
		$self->_focus_settings;
		return $tab;
	}

	# ---------------------------------------------------------------------
	# Showing the active tab
	# ---------------------------------------------------------------------

	# Shows the active tab in the settings pane; the focus stays in the
	# pane when it was there.
	method _show_active () {
		my $tab     = $self->active_tab;
		my $focused = $ui->interaction->get_focused_widget;
		my $had     = defined $focused && $content->contains($focused);
		$strip->active($active);
		if ( !defined $tab ) {
			$self->_show_content($welcome);
			$preview_title->markup('Preview');
			$mode_switch->disabled(1);
			$ui->preview_theme( Term::Fabulous::Theme->builtin('dark') );
			$self->_paint_preview_background( Term::Fabulous::Theme->builtin('dark') );
			$gallery->show_theme( Term::Fabulous::Theme->builtin('dark') ) if defined $gallery;
			return;
		}
		$mode_switch->disabled(0);
		$mode_switch->value( $tab->mode );
		if ( $tab->mode eq 'form' ) {
			$self->_show_content($form);
		}
		else {
			$text_box->clear_children if !$text_box->has_child( $tab->area );
			$text_box->add_child( $tab->area, $errors_text ) unless $text_box->has_child( $tab->area );
			$self->_show_content($text_box);
		}
		$self->_refresh;
		$self->_focus_settings if $had;
		return;
	}

	method _show_content ($widget) {
		return if $content->has_child($widget);
		$content->clear_children;
		$content->add_child($widget);
		return;
	}

	# Everything that follows the active tab's document: the preview, the
	# form or the error list, the titles.
	method _refresh () {
		my $tab      = $self->active_tab // return;
		my $document = $tab->document;
		my $theme    = $tab->preview_theme;
		$ui->preview_theme($theme);
		$self->_paint_preview_background($theme);
		$gallery->show_theme( $theme, $document->has_syntax_error ? () : $document->variants ) if defined $gallery;

		my @errors = $document->errors;
		my $danger = _hex_of( $ui->theme->token('danger') );
		$preview_title->markup( 'Preview: ' . _escaped( $theme->name // _title_of($tab) ) . ( $tab->is_stale ? " [bold $danger](stale: the text has errors)[/]" : '' ) );
		$settings_title->markup( 'Settings of ' . _escaped( _title_of($tab) ) );

		if ( $tab->mode eq 'form' ) {
			my $shown = $tab->is_stale ? $self->_last_valid_document($tab) : $document;
			$form->show( $tab, $shown, @{ $tab->form_state->{new_variants} // [] } );
			$form->read_only( $tab->is_stale );
			@errors
				? $form->show_banner(
				sprintf(
					"[bold]The text has %d error%s[/]; the form shows its last valid state and takes no changes. F8 shows the first error in text mode.\n", scalar @errors, @errors == 1 ? '' : 's'
				)
				)
				: $form->hide_banner;
			$form->explain_current;
		}
		else {
			$errors_text->markup( join "\n", map { "[bold $danger]Line $_->{line}:[/] " . _escaped( $_->{message} ) } @errors[ 0 .. min( 2, $#errors ) ] );
			$errors_text->markup( $errors_text->text . "\n... and " . ( @errors - 3 ) . ' more' ) if @errors > 3;
		}
		return;
	}

	# The preview lies on the edited theme's screen background (none when
	# the token has alpha 0: the terminal's own background shows).
	method _paint_preview_background ($theme) {
		my $background = $theme->token('background');
		$background->[3] > 0 ? $preview_root->background_color($background) : $preview_root->reset_look('background_color');
		return;
	}

	sub _hex_of ($rgba) {
		return sprintf( '#%02x%02x%02x', @{$rgba}[ 0 .. 2 ] );
	}

	sub _escaped ($text) {
		return $text =~ s/\[/\\[/gr;
	}

	field %last_valid;    # tab => the last document without errors

	method _last_valid_document ($tab) {
		return $last_valid{ refaddr $tab } // Term::Fabulous::Theme::Document->parse('');
	}

	# ---------------------------------------------------------------------
	# The text changes
	# ---------------------------------------------------------------------

	# Text typed in text mode is parsed once it rests for a moment; without
	# a running loop (in tests) at once.
	method _text_changed ($tab) {
		return unless defined $tab;
		my $loop = $ui->loop;
		return $self->_sync($tab) unless defined $loop;
		if ( !defined $parse_timer ) {
			weaken( my $editor = $self );
			$parse_timer = IO::Async::Timer::Countdown->new( delay => PARSE_DELAY, on_expire => sub { $editor->_sync( $editor->active_tab ) } );
			$loop->add($parse_timer);
		}
		$parse_timer->is_running ? $parse_timer->reset : $parse_timer->start;
		return;
	}

	# Parses a tab's text when it changed and shows the result.
	method _sync ($tab) {
		return unless defined $tab;
		my $changed = $tab->sync;
		$last_valid{ refaddr $tab } = $tab->document if $tab->document->is_valid;
		$self->_refresh if $changed && defined $self->active_tab && refaddr $tab == refaddr $self->active_tab;
		return $changed;
	}

	# A change the editor makes (from the form, a paste, a reset): one undo
	# step, shown at once.
	method _change ( $what, $change ) {
		my $tab = $self->active_tab // return 0;
		my $changed;
		try {
			$changed = $tab->change_document($change);
		}
		catch ($error) {
			$error =~ s/\ATerm::Fabulous::Theme::Document: //;
			$error =~ s/ at \S+ line \d+\.?\n?\z//;
			$error =~ s/ \(known: [^)]*\)//g;    # the status line has one row
			$error =~ s/\s+\z//;
			$status->message( "Not changed: $error", 'danger' );
			return 0;
		}
		$last_valid{ refaddr $tab } = $tab->document if $tab->document->is_valid;
		$self->_refresh;
		$status->message( $changed ? $what : 'Nothing changed.', $changed ? 'success' : 'info' );
		return $changed;
	}

	# ---------------------------------------------------------------------
	# Modes, panes and focus
	# ---------------------------------------------------------------------

	method set_mode ($mode) {
		my $tab = $self->active_tab // return;
		return if $tab->mode eq $mode;
		$self->_sync($tab);
		my $place = $tab->mode eq 'form' ? $self->_line_of_cursor_row : $self->_key_on_text_line;
		$form->keep_state($tab) if $tab->mode eq 'form';
		$tab->mode($mode);
		$self->_show_active;
		$self->_focus_settings;
		$mode eq 'text' ? $self->_put_text_cursor($place) : $self->_put_form_cursor($place);
		$status->message( $mode eq 'form' ? 'Form mode: Enter edits a setting, Delete resets it.' : 'Text mode: the file as it is; the preview follows your typing.' );
		return;
	}

	# The line of the text that holds the setting under the form's cursor
	# (for a section, its first setting the theme sets), or undef.
	method _line_of_cursor_row () {
		my $tab    = $self->active_tab // return undef;
		my $row    = $form->current    // return undef;
		my @keys   = defined $row->{key} ? ( $row->{key} ) : $form->keys_in( $row->{id} );
		my ($line) = sort { $a <=> $b } grep { defined } map { $tab->document->line_of($_) } @keys;
		return $line;
	}

	# The setting on the line of the text cursor (or the nearest one above
	# it), or undef.
	method _key_on_text_line () {
		my $tab      = $self->active_tab // return undef;
		my ($row)    = $tab->area->editor->cursor;
		my $document = $tab->document;
		my ($key)    = sort { $document->line_of($b) <=> $document->line_of($a) } grep { $document->line_of($_) <= $row + 1 } $document->setting_keys;
		return $key;
	}

	method _put_text_cursor ($line) {
		my $tab = $self->active_tab // return;
		return unless defined $line;
		my $editor = $tab->area->editor;
		$editor->move_to( min( $line - 1, $editor->line_count - 1 ), 0 );
		$tab->area->mark_changed;
		return;
	}

	method _put_form_cursor ($key) {
		return unless defined $key && $form->has_row($key);
		$form->go_to($key);
		return;
	}

	method _toggle_mode () {
		my $tab = $self->active_tab // return;
		$self->set_mode( $tab->mode eq 'form' ? 'text' : 'form' );
		return;
	}

	method _focus_settings () {
		my $tab    = $self->active_tab;
		my $target = !defined $tab ? undef : $tab->mode eq 'form' ? $form->list : $tab->area;
		$ui->interaction->set_focused_widget($target) if !defined $target || $ui->interaction->can_take_focus($target);
		return;
	}

	method _switch_pane () {
		my $focused = $ui->interaction->get_focused_widget;
		if ( defined $focused && $preview_root->contains($focused) ) {
			$self->_focus_settings;
			return;
		}
		my $first = first { $_->can('can_focus') && $ui->interaction->can_take_focus($_) } $preview_root->descendants;
		$ui->interaction->set_focused_widget($first) if defined $first;
		$status->message('In the preview: Tab moves between the widgets, PageUp and PageDown scroll, F6 goes back.');
		return;
	}

	# The pane with the focus gets its border in the accent color.
	method _focus_moved () {
		my $focused = $ui->interaction->get_focused_widget;
		foreach my $pane ( $preview_pane, $settings_pane ) {
			my $has = defined $focused && $pane->contains($focused);
			$has ? $pane->border_color( $pane->family_look( input => 'accent' ) ) : $pane->reset_look('border_color');
		}
		return;
	}

	# The form's cursor moved: the preview shows the family of the row.
	method _cursor_moved ($id) {
		return unless defined $gallery && defined $id;
		my $section = $form->section_of($id) // return;
		my ( $kind, $family ) = $section =~ /\A#(\w+)(?::(\w+))?/;
		my $target = $kind eq 'palette' ? 'palette' : $kind eq 'theme' ? 'palette' : $gallery->section_of_family($family);
		$target = 'variants' if $kind eq 'variant';
		$gallery->show_section($target) if defined $target;
		return;
	}

	method _toggle_only_set () {
		my $box = $form->only_set;
		$box->checked( $box->checked ? 0 : 1 );
		$box->fire_change( $box->checked );
		return;
	}

	# ---------------------------------------------------------------------
	# Keys
	# ---------------------------------------------------------------------

	method _key ($event) {
		my $name = $event->key_name // return 0;
		return 1 if $menu->handle_shortcut($event);
		if ( my ($number) = $name =~ /\AAlt\+([1-9])\z/ ) {
			$self->select_tab( $number - 1 ) if $number <= @tabs;
			return 1;
		}
		if ( $name eq 'Escape' ) {
			return $self->_escape;
		}
		my $command = $commands->command_for_key($name) // return 0;
		my $id      = $command->id;
		return 0 if ( $id eq 'edit' || $id eq 'reset' ) && !$self->_form_has_focus;
		$command->run or $self->_not_now($id);
		return 1;
	}

	method _not_now ($id) {
		my %why = (
			save       => 'No theme is open.',
			paste_keys => 'Pasting at the copied keys works in form mode, on a theme without errors.',
			edit       => 'Editing works in form mode, on a theme without errors.',
			reset      => 'Resetting works in form mode, on a theme without errors.',
			undo       => 'Nothing to undo.',
			redo       => 'Nothing to redo.',
			revert     => 'The theme has no file to revert to.',
			find_next  => 'Find something first (Ctrl+F).',
			next_error => 'The theme has no errors.',
		);
		$status->message( $why{$id} // ( $commands->command($id)->label =~ s/\.\.\.\z//r ) . ' is not available now.', 'warning' );
		return;
	}

	method _form_has_focus () {
		my $focused = $ui->interaction->get_focused_widget // return 0;
		return $form->list->contains($focused) ? 1 : 0;
	}

	# Escape in the search field empties it and goes back to the list.
	method _escape () {
		my $focused = $ui->interaction->get_focused_widget // return 0;
		my $search  = $form->search;
		return 0 unless refaddr $focused == refaddr $search;
		if ( length $search->value ) {
			$search->value('');
			$form->list->search('');
		}
		$ui->interaction->set_focused_widget( $form->list );
		return 1;
	}

	# ---------------------------------------------------------------------
	# Editing settings
	# ---------------------------------------------------------------------

	method _writable_tab () {
		my $tab = $self->active_tab // return undef;
		$self->_sync($tab);
		if ( !$tab->document->is_valid ) {
			$status->message( 'The text has errors; fix them first (F8 shows the first one).', 'warning' );
			return undef;
		}
		return $tab;
	}

	method _edit_current () {
		my $key = $form->current_key // return;
		$self->_edit_key($key);
		return;
	}

	# Opens the dialog that edits a setting.
	method _edit_key ($key) {
		my $tab       = $self->_writable_tab // return;
		my $document  = $tab->document;
		my $effective = $document->effective_setting($key);
		my $fallback  = $document->without_setting($key)->effective_setting($key);
		my $palette   = $tab->preview_theme->palette;
		weaken( my $editor = $self );
		my $dialog = Term::Fabulous::ThemeEditor::ValueDialog->new(
			key        => $key,
			current    => $effective->{spec},
			is_set     => $effective->{origin} eq 'set' ? 1 : 0,
			default    => $fallback->{spec},
			palette    => $palette,
			on_preview => sub ($value) { $editor->_preview_value( $key, $value ) },
			on_apply   => sub ($value) { $editor->set_setting( $key, $value ) },
			on_reset   => sub () { $editor->reset_setting($key) },
			list_rows  => $self->_list_rows(19),
		);
		$dialog->open($ui);
		$status->message('Choose a value: the preview shows it. Enter applies, Escape leaves the theme as it was.');
		return $dialog;
	}

	# Shows a value in the preview before it is applied (undef: the theme
	# as it is).
	method _preview_value ( $key, $value ) {
		my $tab   = $self->active_tab // return;
		my $theme = $tab->preview_theme;
		if ( defined $value ) {
			try {
				$theme = $tab->document->with_setting( $key, $value )->theme // $theme;
			}
			catch ($error) {

				# a value the key cannot take: the preview stays
			}
		}
		$ui->preview_theme($theme);
		return;
	}

	method set_setting ( $key, $value ) {
		return 0 unless $self->_writable_tab;
		my $changed = $self->_change( "Set $key to $value.", sub ($document) { $document->with_setting( $key, $value ) } );
		$self->_forget_new_variant($key) if $changed;
		return $changed ? 1 : 0;
	}

	method reset_setting ($key) {
		my $tab = $self->_writable_tab // return 0;
		if ( !defined $tab->document->setting($key) ) {
			$status->message( "$key is not set; it follows " . _origin_words( $tab->document->effective_setting($key) ) . ' already.' );
			return 0;
		}
		my $changed = $self->_change(
			"Reset $key; it follows " . _origin_words( $tab->document->without_setting($key)->effective_setting($key) ) . ' now.',
			sub ($document) { $document->without_setting($key) }
		);
		return $changed ? 1 : 0;
	}

	# Where a value comes from, and the value; a token is named as a token
	# (a token may be called like a state: disabled).
	sub _origin_words ($effective) {
		my %words = ( default => 'the default', normal => 'the normal state', family => 'its family', dark => 'the dark theme', light => 'the light theme', set => 'the theme' );
		my $spec  = $effective->{spec};
		my $value = !defined $spec ? '' : ( grep { $_ eq $spec } Term::Fabulous::Theme::tokens() ) ? qq{ (the token "$spec")} : " ($spec)";
		return ( $words{ $effective->{origin} } // $effective->{origin} ) . $value;
	}

	method _reset_current () {
		my $row = $form->current // return;
		return $self->reset_setting( $row->{key} ) if defined $row->{key};
		return $self->_reset_section;
	}

	# Resets every setting of the section under the cursor, after asking.
	method _reset_section () {
		my $tab     = $self->_writable_tab            // return;
		my $row     = $form->current                  // return;
		my $section = $form->section_of( $row->{id} ) // return;
		my @keys    = grep { defined $tab->document->setting($_) } $form->keys_in($section);
		my $name    = $section =~ s/\A#\w+:?//r =~ s/:/[/r;
		$name = $section eq '#theme' ? 'the theme node' : $section eq '#palette' ? 'the palette' : $section =~ /\A#variant/ ? "the variant $name]" : "the family $name";
		if ( !@keys ) {
			$status->message("Nothing to reset: $name sets nothing.");
			return;
		}
		$self->_ask(
			title   => 'Reset section',
			message => sprintf( 'Reset the %d setting%s of %s to their defaults? Undo (Ctrl+Z) takes it back.', scalar @keys, @keys == 1 ? '' : 's', $name ),
			buttons => [ { id => 'reset', label => 'Reset', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return unless $button eq 'reset';
				$self->_change(
					sprintf( 'Reset %d setting%s of %s.', scalar @keys, @keys == 1 ? '' : 's', $name ),
					sub ($document) {
						$document->with_settings( [ map { [ $_, undef ] } @keys ] );
					}
				);
			},
		);
		return;
	}

	method _reset_theme () {
		my $tab  = $self->_writable_tab // return;
		my @keys = grep { !/\Atheme\./ } $tab->document->setting_keys;
		if ( !@keys ) {
			$status->message('The theme sets nothing besides its name and base.');
			return;
		}
		$self->_ask(
			title   => 'Reset whole theme',
			message => sprintf( 'Remove all %d settings, so the theme is its base theme (%s) again? Its name and base stay. Undo (Ctrl+Z) takes it back.', scalar @keys, $tab->document->extends ),
			buttons => [ { id => 'reset', label => 'Reset', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return unless $button eq 'reset';
				$self->_change(
					sprintf( 'Removed %d settings.', scalar @keys ),
					sub ($document) {
						$document->with_settings( [ map { [ $_, undef ] } @keys ] );
					}
				);
			},
		);
		return;
	}

	# ---------------------------------------------------------------------
	# Variants
	# ---------------------------------------------------------------------

	method _current_variant () {
		my $row     = $form->current                  // return undef;
		my $section = $form->section_of( $row->{id} ) // return undef;
		my ( $family, $variant ) = $section =~ /\A#variant:(\w+):(.+)\z/ or return undef;
		return [ $family, $variant ];
	}

	method _ask_add_variant () {
		my $tab      = $self->_writable_tab // return;
		my $row      = $form->current;
		my $section  = defined $row ? $form->section_of( $row->{id} ) // '' : '';
		my ($family) = $section =~ /\A#(?:family|variant):(\w+)/;
		$self->_ask(
			title   => 'Add variant',
			message => 'A variant changes some settings of a family for the widgets whose [bold]classes[/] name it, such as a button made with classes => [\'primary\'].',
			fields  => [
				{
					name  => 'family', label => 'Family',
					input => Term::Fabulous::Widget::Dropdown->new( options => [ Term::Fabulous::Theme::families() ], value => $family // 'button', max_visible_options => 10 )
				},
				{
					name  => 'name',
					label => 'Name',
					input => _text_input(
						placeholder      => 'primary',
						required         => 1,
						required_message => 'A variant needs a name.',
						validator        => sub ($value) { $value =~ /\A[A-Za-z0-9_-]+\z/ ? undef : 'A name is a word: letters, digits, _ and -.' },
					),
				},
			],
			check => sub ($values) {
				return 'The theme has this variant already.' if grep { $_->[0] eq $values->{family} && $_->[1] eq $values->{name} } $tab->document->variants;
				return undef;
			},
			buttons => [ { id => 'add', label => 'Add', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return unless $button eq 'add';
				push @{ $tab->form_state->{new_variants} }, [ $values->{family}, $values->{name} ];
				$self->_refresh;
				my $id = Term::Fabulous::ThemeEditor::Form::section_id( 'variant', $values->{family}, $values->{name} );
				$form->go_to($id);
				$status->message("Added the variant $values->{family}\[$values->{name}]. Set some of its settings; until then the file does not hold it.");
			},
		);
		return;
	}

	method _forget_new_variant ($key) {
		my $tab    = $self->active_tab // return;
		my $parsed = Term::Fabulous::Theme::Document::parse_key($key);
		return unless defined $parsed->{variant};
		my $pending = $tab->form_state->{new_variants} // return;
		@$pending = grep { !( $_->[0] eq $parsed->{family} && $_->[1] eq $parsed->{variant} ) } @$pending;
		return;
	}

	method _remove_variant () {
		my $variant = $self->_current_variant // return;
		my ( $family, $name ) = @$variant;
		my $tab     = $self->_writable_tab             // return;
		my $pending = $tab->form_state->{new_variants} // [];
		if ( grep { $_->[0] eq $family && $_->[1] eq $name } @$pending ) {
			@$pending = grep { !( $_->[0] eq $family && $_->[1] eq $name ) } @$pending;
			$self->_refresh;
			$status->message("Removed the variant $family\[$name].");
			return;
		}
		$self->_change( "Removed the variant $family\[$name].", sub ($document) { $document->without_variant( $family, $name ) } );
		return;
	}

	# ---------------------------------------------------------------------
	# Undo, clipboard
	# ---------------------------------------------------------------------

	method _undo () {
		return $self->_history('undo');
	}

	method _redo () {
		return $self->_history('redo');
	}

	# Undo and redo; in form mode the cursor goes to the first setting that
	# changed.
	method _history ($which) {
		my $tab = $self->active_tab // return 0;
		$self->_sync($tab);
		my $before = $tab->document;
		return 0 unless $tab->$which;
		$last_valid{ refaddr $tab } = $tab->document if $tab->document->is_valid;
		$self->_refresh;
		my @changed = _changed_keys( $before, $tab->document );
		$form->go_to( $changed[0] ) if @changed && $tab->mode eq 'form' && $form->has_row( $changed[0] );
		$status->message( ( $which eq 'undo' ? 'Undone' : 'Redone' ) . ( @changed ? ': ' . join( ', ', @changed[ 0 .. min( 2, $#changed ) ] ) . ( @changed > 3 ? ', ...' : '' ) : '' ) . '.' );
		return 1;
	}

	sub _changed_keys ( $before, $after ) {
		my %keys = map { $_ => 1 } $before->setting_keys, $after->setting_keys;
		return grep { ( $before->setting($_) // "\x{0}" ) ne ( $after->setting($_) // "\x{0}" ) }
			sort { ( $after->line_of($a) // $before->line_of($a) // 0 ) <=> ( $after->line_of($b) // $before->line_of($b) // 0 ) } keys %keys;
	}

	method _in_text_mode () {
		my $tab = $self->active_tab // return 0;
		return $tab->mode eq 'text' ? 1 : 0;
	}

	# In text mode, the clipboard commands work on the text; in form mode
	# on settings, as KDL that the text mode can paste too.
	method _copy () {
		my $tab = $self->active_tab // return;
		if ( $self->_in_text_mode ) {
			my $editor = $tab->area->editor;
			if ( !$editor->has_selection ) {
				$status->message( 'Select some text to copy.', 'warning' );
				return;
			}
			$editor->_copy;
			$status->message('Copied the selection.');
			return;
		}
		my @keys = $self->_keys_to_copy;
		return unless @keys;
		my $document = $self->_shown_document($tab);
		my $fragment
			= Term::Fabulous::Theme::Document->parse('')->with_settings( [ map { [ $_, $document->effective_setting($_)->{spec} ] } grep { defined $document->effective_setting($_)->{spec} } @keys ] );
		Term::Fabulous::Editor->clipboard( $fragment->text );
		$status->message( @keys == 1 ? "Copied $keys[0] (" . $document->effective_setting( $keys[0] )->{spec} . ').' : sprintf( 'Copied %d settings.', scalar @keys ), 'success' );
		return @keys;
	}

	method _shown_document ($tab) {
		return $tab->is_stale ? $self->_last_valid_document($tab) : $tab->document;
	}

	# The keys a copy takes: the setting under the cursor, or the settings
	# a section sets.
	method _keys_to_copy () {
		my $row = $form->current;
		if ( !defined $row ) {
			$status->message( 'Put the cursor on a setting or a section to copy.', 'warning' );
			return;
		}
		return ( $row->{key} ) if defined $row->{key};
		my $document = $self->_shown_document( $self->active_tab );
		my @keys     = grep { defined $document->setting($_) } $form->keys_in( $row->{id} );
		$status->message( 'This section sets nothing to copy.', 'warning' ) unless @keys;
		return @keys;
	}

	method _cut () {
		my $tab = $self->active_tab // return;
		if ( $self->_in_text_mode ) {
			if ( !$tab->area->editor->has_selection ) {
				$status->message( 'Select some text to cut.', 'warning' );
				return;
			}
			$tab->area->apply_edit( $tab->area->editor->cut );
			$self->_sync($tab);
			return;
		}
		return unless $self->_writable_tab;
		my @keys = $self->_copy or return;
		my @set  = grep { defined $tab->document->setting($_) } @keys;
		$self->_change(
			@keys == 1 ? "Cut $keys[0]." : sprintf( 'Cut %d settings.', scalar @set ),
			sub ($document) {
				$document->with_settings( [ map { [ $_, undef ] } @set ] );
			}
		) if @set;
		return;
	}

	# Pastes the clipboard: in text mode as text; in form mode one copied
	# value onto the setting under the cursor, or copied settings at their
	# own keys (always with at_keys).
	method _paste (%options) {
		my $tab       = $self->active_tab // return;
		my $clipboard = Term::Fabulous::Editor->clipboard;
		if ( $self->_in_text_mode ) {
			$tab->area->apply_edit( $tab->area->editor->paste );
			$self->_sync($tab);
			return;
		}
		return unless $self->_writable_tab;
		my @entries = _settings_in($clipboard);
		my $target  = $form->current_key;
		my ($word)  = $clipboard =~ /\A\s*(\S+)\s*\z/;
		my $value   = @entries == 1 ? $entries[0][1] : @entries ? undef : $word;
		return $self->set_setting( $target, $value ) if !$options{at_keys} && defined $target && defined $value;
		if ( !@entries ) {
			$status->message( 'The clipboard holds no theme settings. Copy a setting or a section first (Ctrl+C).', 'warning' );
			return;
		}
		$self->_change(
			sprintf( 'Pasted %d setting%s at %s.', scalar @entries, @entries == 1 ? '' : 's', @entries == 1 ? $entries[0][0] : 'their keys' ),
			sub ($document) { $document->with_settings( \@entries ) }
		);
		$self->_forget_new_variant( $_->[0] ) foreach @entries;
		return;
	}

	# The [ key, value ] settings a text holds when it is a theme fragment.
	sub _settings_in ($text) {
		return () unless length $text;
		my $document = Term::Fabulous::Theme::Document->parse($text);
		return () unless $document->is_valid;
		return map { [ $_, $document->setting($_) ] } $document->setting_keys;
	}

	# ---------------------------------------------------------------------
	# Finding
	# ---------------------------------------------------------------------

	# In form mode, the search field; in text mode, a word to find.
	method _find () {
		my $tab = $self->active_tab // return;
		if ( $tab->mode eq 'form' ) {
			$ui->interaction->set_focused_widget( $form->search );
			$status->message('Type to filter the settings; Enter or Down goes to them, Escape empties the field.');
			return;
		}
		$self->_ask(
			title   => 'Find',
			fields  => [ { name => 'text', label => 'Find', input   => _text_input( value => $find_text ) } ],
			buttons => [ { id   => 'find', label => 'Find', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return unless $button eq 'find' && length $values->{text};
				$find_text = $values->{text};
				$self->_find_next;
			},
		);
		return;
	}

	method _find_next () {
		my $tab = $self->active_tab // return;
		return $self->_find unless $tab->mode eq 'text';
		my $editor = $tab->area->editor;
		my @lines  = $editor->lines;
		my ( $row, $offset ) = $editor->has_selection ? ( $editor->selection )[ 2, 3 ] : $editor->cursor;
		my $needle = fc $find_text;
		foreach my $step ( 0 .. scalar @lines ) {
			my $index = ( $row + $step ) % @lines;
			my $from  = $step == 0 ? $offset : 0;
			my $at    = index( fc $lines[$index], $needle, $from );
			next if $at < 0;
			$editor->set_selection( $index, $at, $index, $at + length $find_text );
			$tab->area->mark_changed;
			$status->message( "Found \"$find_text\" on line " . ( $index + 1 ) . '. F3 finds the next one.' );
			$ui->interaction->set_focused_widget( $tab->area );
			return;
		}
		$status->message( "\"$find_text\" is not in the text.", 'warning' );
		return;
	}

	# Shows the first error after the cursor in text mode.
	method _next_error () {
		my $tab = $self->active_tab // return;
		$self->_sync($tab);
		my @errors = $tab->document->errors or return;
		$self->set_mode('text') unless $tab->mode eq 'text';
		my $editor = $tab->area->editor;
		my ($row)  = $editor->cursor;
		my $error  = ( first { $_->{line} - 1 > $row } @errors ) // $errors[0];
		my $line   = min( $error->{line} - 1, $editor->line_count - 1 );
		$editor->move_to( $line, 0 );
		$editor->move_line_end(1);
		$tab->area->mark_changed;
		$ui->interaction->set_focused_widget( $tab->area );
		$status->message( "Line $error->{line}: $error->{message}", 'danger' );
		return;
	}

	# ---------------------------------------------------------------------
	# Files
	# ---------------------------------------------------------------------

	# How many rows a list in a dialog gets: what the screen has left
	# besides the dialog's other rows, between 4 and 10.
	method _list_rows ($other_rows) {
		return max( 4, min( 10, $ui->height - $other_rows ) );
	}

	# Opens a prompt; on_done gets the id of the button that answered it
	# and the values of its fields.
	method _ask (%parameters) {
		my $on_done = delete $parameters{on_done};
		my $prompt  = Term::Fabulous::Widget::Prompt->new(%parameters);
		$prompt->on( Answer => sub ($event) { $on_done->( $event->button, $event->values ) if defined $on_done; return } );
		$prompt->open($ui);
		return $prompt;
	}

	# A text field that grows to the width of the prompt, its text selected
	# so typing replaces it.
	sub _text_input (%parameters) {
		my $input = Term::Fabulous::Widget::TextField->new( %parameters, layout => { sizing => { width => sizing_grow() } } );
		$input->editor->select_all;
		return $input;
	}

	method _tell ( $title, $message ) {
		return $self->_ask( title => $title, message => _escaped($message) );
	}

	method _ask_new_theme () {
		weaken( my $editor = $self );
		my $number = $untitled_count + 1;
		$self->_ask(
			title   => 'New theme',
			message => 'A theme starts from one of the built-in themes and changes what you set.',
			fields  => [
				{ name => 'name', label => 'Name',     input => _text_input( value => "untitled-$number", required => 1, required_message => 'A theme needs a name.' ) },
				{ name => 'base', label => 'Based on', input => Term::Fabulous::Widget::SegmentedControl->new( options => [ Term::Fabulous::Theme::builtin_names() ], value => 'dark' ) },
			],
			buttons => [ { id => 'create', label => 'Create', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return unless $button eq 'create';
				$editor->new_theme( name => $values->{name}, extends => $values->{base} );
				$editor->_focus_settings;
				$editor->status->message("Made the theme $values->{name}, based on $values->{base}.");
			},
		);
		return;
	}

	method _ask_open () {
		weaken( my $editor = $self );
		my $tab    = $self->active_tab;
		my $start  = defined $tab && defined $tab->path ? dirname( abs_path( $tab->path ) // $tab->path ) : $directory;
		my $dialog = Term::Fabulous::Widget::FileDialog->new(
			mode      => 'open',
			title     => 'Open a theme',
			filters   => THEME_FILTERS,
			list_rows => $self->_list_rows(20),
			directory => -d $start ? $start : $directory,
		);
		$dialog->on(
			Answer => sub ($event) {
				return if $event->button eq 'cancel';
				try {
					$editor->open_file( $event->values->{path} );
					$editor->_focus_settings;
				}
				catch ($error) {
					$error =~ s/\ATerm::Fabulous::Theme::Document: //;
					$editor->_tell( 'Cannot open the file', $error );
				}
				return;
			}
		);
		$dialog->open($ui);
		return;
	}

	# Saves the active tab: to its file, or (untitled) where the user says.
	# A theme with errors and a file changed on the disk are saved after a
	# question. $then runs after a successful save.
	method _save ( $tab = $self->active_tab, $then = undef ) {
		return unless defined $tab;
		$self->_sync($tab);
		return $self->_save_as( $tab, $then ) unless defined $tab->path;
		my @steps = (
			sub ($next) {
				my @errors = $tab->document->errors;
				return $next->() unless @errors;
				$self->_ask(
					title   => 'The theme has errors',
					message => sprintf(
						"%s has %d error%s; the first is on line %d: %s\n\nA program cannot load the file until they are fixed. Save it anyway?", _title_of($tab), scalar @errors,
						@errors == 1 ? '' : 's',
						$errors[0]{line}, _escaped( $errors[0]{message} )
					),
					buttons => [ { id => 'save', label => 'Save anyway', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
					on_done => sub ( $button, $values ) { $next->() if $button eq 'save' },
				);
			},
			sub ($next) {
				return $next->() unless $tab->changed_on_disk;
				$self->_ask(
					title   => 'The file changed',
					message => _escaped( _decoded( $tab->path ) ) . ' was changed by another program since it was opened or saved. Overwrite it with the theme from the editor?',
					buttons => [ { id => 'save', label => 'Overwrite', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
					on_done => sub ( $button, $values ) { $next->() if $button eq 'save' },
				);
			},
			sub ($next) {
				$self->_write( $tab, $tab->path ) or return;
				$then->() if defined $then;
			},
		);
		_chain(@steps);
		return;
	}

	# Runs steps that each get the next one to continue with.
	sub _chain (@steps) {
		my $step = shift @steps // return;
		$step->( sub { _chain(@steps) } );
		return;
	}

	method _write ( $tab, $path ) {
		try {
			$tab->save($path);
		}
		catch ($error) {
			$error =~ s/\ATerm::Fabulous::Theme::Document: //;
			$self->_tell( 'Cannot save', $error );
			return 0;
		}
		$status->message( 'Saved ' . $self->_shown_path( $tab->path ) . '.', 'success' );
		return 1;
	}

	method _save_as ( $tab = $self->active_tab, $then = undef ) {
		return unless defined $tab;
		weaken( my $editor = $self );
		my $start  = defined $tab->path ? dirname( abs_path( $tab->path ) // $tab->path ) : $directory;
		my $name   = defined $tab->path ? basename( $tab->path )                          : encode( 'UTF-8', ( $tab->document->name // _title_of($tab) ) . '.kdl' );
		my $dialog = Term::Fabulous::Widget::FileDialog->new(
			mode              => 'save',
			title             => 'Save the theme as',
			filters           => THEME_FILTERS,
			default_extension => 'kdl',
			current_file      => defined $tab->path ? File::Spec->rel2abs( $tab->path ) : undef,
			list_rows         => $self->_list_rows(20),
			directory         => -d $start ? $start : $directory,
			name              => $name,
		);
		$dialog->on(
			Answer => sub ($event) {
				return if $event->button eq 'cancel';
				$editor->_write( $tab, $event->values->{path} ) && $then && $then->();
				return;
			}
		);
		$dialog->open($ui);
		return;
	}

	method _save_all ( $then = undef ) {
		my @unsaved = grep { $_->is_modified } @tabs;
		_chain(
			(
				map {
					my $tab = $_;
					sub ($next) { $self->_save( $tab, $next ) }
				} @unsaved
			),
			sub ($next) { $then->() if defined $then }
		);
		return;
	}

	method _revert () {
		my $tab = $self->active_tab // return;
		my $go  = sub {
			try {
				$tab->revert;
			}
			catch ($error) {
				$error =~ s/\ATerm::Fabulous::Theme::Document: //;
				return $self->_tell( 'Cannot revert', $error );
			}
			$self->_sync($tab);
			$self->_refresh;
			$status->message( 'Reverted to ' . $self->_shown_path( $tab->path ) . '. Undo (Ctrl+Z) takes it back.', 'success' );
		};
		return $go->() unless $tab->is_modified;
		$self->_ask(
			title   => 'Revert to saved',
			message => 'Replace the theme in the editor with ' . _escaped( _decoded( $tab->path ) ) . ' as it is on the disk? Undo (Ctrl+Z) takes it back.',
			buttons => [ { id => 'revert', label => 'Revert', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) { $go->() if $button eq 'revert' },
		);
		return;
	}

	method _duplicate () {
		my $tab = $self->active_tab // return;
		$self->_sync($tab);
		my $number = ++$untitled_count;
		my $text   = $tab->text;
		my $name   = $tab->document->name;
		if ( !$tab->document->has_syntax_error ) {
			$text = $tab->document->with_setting( 'theme.name', ( $name // _title_of($tab) ) . '-copy' )->text;
		}
		$self->_add_tab( Term::Fabulous::ThemeEditor::Tab->new( untitled => $number, text => $text, modified => 1 ) );
		$self->_focus_settings;
		$status->message( 'Made a copy of ' . _title_of($tab) . ' as a new theme.' );
		return;
	}

	# Closes a tab, asking first when it has unsaved changes.
	method close_tab ( $index = $active ) {
		return unless defined $index && $tabs[$index];
		my $tab = $tabs[$index];
		$self->_sync($tab);
		weaken( my $editor = $self );
		my $close = sub {
			my $found = first { refaddr $tabs[$_] == refaddr $tab } 0 .. $#tabs;
			$editor->_remove_tab($found) if defined $found;
			delete $last_valid{ refaddr $tab };
			$status->message( 'Closed ' . _title_of($tab) . '.' );
		};
		return $close->() unless $tab->is_modified;
		$self->select_tab($index);
		$self->_ask(
			title   => 'Unsaved changes',
			message => 'Save the changes to ' . _escaped( _title_of($tab) ) . ' before closing it?',
			buttons => [ { id => 'save', label => 'Save', primary => 1 }, { id => 'discard', label => 'Close without saving' }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return $editor->_save( $tab, $close ) if $button eq 'save';
				$close->() if $button eq 'discard';
			},
		);
		return;
	}

	# Quits, asking first when a theme has unsaved changes.
	method _quit () {
		$self->_sync($_) foreach @tabs;
		my @unsaved = grep { $_->is_modified } @tabs;
		weaken( my $editor = $self );
		my $stop = sub { $quitting = 1; $ui->loop->stop if defined $ui->loop };
		return $stop->() unless @unsaved;
		$self->_ask(
			title   => 'Unsaved changes',
			message => sprintf(
				"%d theme%s %s unsaved changes: %s.\n\nSave %s before quitting?", scalar @unsaved, @unsaved == 1 ? '' : 's', @unsaved == 1 ? 'has' : 'have',
				join( ', ', map { _escaped( _title_of($_) ) } @unsaved ), @unsaved == 1 ? 'it' : 'them'
			),
			buttons => [ { id => 'save', label => @unsaved == 1 ? 'Save' : 'Save all', primary => 1 }, { id => 'discard', label => 'Quit without saving' }, { id => 'cancel', label => 'Cancel' } ],
			on_done => sub ( $button, $values ) {
				return $editor->_save_all($stop) if $button eq 'save';
				$stop->() if $button eq 'discard';
			},
		);
		return;
	}

	method is_quitting () {
		return $quitting;
	}

	# ---------------------------------------------------------------------
	# Help
	# ---------------------------------------------------------------------

	# Commands that work in the form only: the key reference lists their keys
	# with the form's.
	my %FORM_COMMAND = map { $_ => 1 } qw(edit reset paste_keys only_set);

	# The commands with keys that work everywhere, and their group.
	use constant COMMAND_GROUP => 'Everywhere';

	method _commands_everywhere () {
		return grep { !$FORM_COMMAND{ $_->id } } $commands->commands;
	}

	method key_list () {
		my @command_keys = map { [ COMMAND_GROUP, $_->keys_text, $_->label =~ s/\.\.\.\z//r ] } grep { $_->keys } $self->_commands_everywhere;
		return ( @command_keys, _other_keys() );
	}

	# The keys that are no commands' (and the form's commands, under The
	# form), in groups in the order they are listed.
	sub _other_keys () {
		return
			[ 'Everywhere',  'Alt+1 to Alt+9',                        'Show the first to the ninth tab' ],
			[ 'Everywhere',  'F10, Alt+F/E/V/T/H',                    'Open the menu bar, or one of its menus' ],
			[ 'Everywhere',  'Tab, Shift+Tab',                        'Move the focus (in text mode: indent, outdent)' ],
			[ 'Menus',       'Left, Right, Tab',                      'Another menu' ],
			[ 'Menus',       'Up, Down, Home, End',                   'Another command' ],
			[ 'Menus',       'Enter, Space',                          'Run the command' ],
			[ 'Menus',       'Escape, F10',                           'Close the menu' ],
			[ 'The form',    'Up, Down, PageUp, PageDown, Home, End', 'Move between settings' ],
			[ 'The form',    'Right, +',                              'Open a section; Right on an open one goes into it' ],
			[ 'The form',    'Left, -',                               'Close a section; on a setting, go to its section' ],
			[ 'The form',    'Enter, double click',                   'Edit the setting; on a section: open or close it' ],
			[ 'The form',    'Delete',                                'Reset the setting to its default; on a section: all of its settings' ],
			[ 'The form',    'Ctrl+C, Ctrl+X',                        'Copy (cut) the setting, or every setting of a section' ],
			[ 'The form',    'Ctrl+V',                                'Paste one value onto the setting, or settings at their keys' ],
			[ 'The form',    'Alt+P',                                 'Paste settings at the keys they were copied from' ],
			[ 'The form',    'Ctrl+F, Escape',                        'Search the settings; empty the search' ],
			[ 'The form',    'Alt+L',                                 'Show only the settings the theme sets' ],
			[ 'Text mode',   'Enter',                                 'New line, indented like the last (more after {)' ],
			[ 'Text mode',   'Tab',                                   'Indent the selected lines; without a selection, insert one level' ],
			[ 'Text mode',   'Shift+Tab',                             'Outdent the line or the selected lines' ],
			[ 'Text mode',   '}',                                     'Typed into the indentation of a line: one level back' ],
			[ 'Text mode',   'Ctrl+C, Ctrl+X, Ctrl+V',                'Copy, cut, paste' ],
			[ 'Text mode',   'Ctrl+Z, Ctrl+Y',                        'Undo, redo (form changes too, up to 100 steps)' ],
			[ 'Text mode',   'Ctrl+A',                                'Select everything' ],
			[ 'Text mode',   'Shift+arrows, Shift+Home, Shift+End',   'Select' ],
			[ 'Text mode',   'Ctrl+Left, Ctrl+Right',                 'A word to the left, to the right' ],
			[ 'Text mode',   'Alt+Backspace, Ctrl+Delete',            'Delete the word before, after the cursor' ],
			[ 'Text mode',   'Ctrl+U, Ctrl+K',                        'Delete to the start, to the end of the line' ],
			[ 'Text mode',   'Ctrl+F, F3',                            'Find, find the next' ],
			[ 'Text mode',   'F8',                                    'Go to the next error' ],
			[ 'The preview', 'F6',                                    'Go to the preview, back to the settings' ],
			[ 'The preview', 'Tab, Shift+Tab',                        'Move between the widgets' ],
			[ 'The preview', 'PageUp, PageDown',                      'Scroll the preview' ],
			[ 'The preview', 'Ctrl+Home, Ctrl+End',                   'The top, the end of the preview' ],
			[ 'Dialogs',     'Tab, Shift+Tab',                        'Move between the fields and buttons' ],
			[ 'Dialogs',     'Enter',                                 'Choose (in a list), press the button' ],
			[ 'Dialogs',     'Escape',                                'Cancel' ],
			[ 'Files',       'Enter',                                 'Open a folder, choose a file' ],
			[ 'Files',       'Backspace',                             'The parent folder' ];
	}

	method _show_keys () {
		Term::Fabulous::Widget::KeyReference->new(
			title    => 'Keys of the theme editor',
			commands => [ $self->_commands_everywhere ],
			group    => COMMAND_GROUP,
			keys     => [ _other_keys() ],
			height   => max( 1, min( 40,  $ui->height - 2 ) ),
			width    => max( 1, min( 100, $ui->width - 2 ) ),
		)->open($ui);
		return;
	}

	method _show_about () {
		$self->_ask(
			title   => 'About',
			message =>
"The theme editor of [bold]Term::Fabulous[/] $Term::Fabulous::ThemeEditor::VERSION.\n\nIt edits theme files: KDL documents that set the palette and the looks of the widget families of Term::Fabulous. Programs load them with Term::Fabulous::Theme->from_file. See perldoc Term::Fabulous::ThemeEditor and Term::Fabulous::Theme.",
		);
		return;
	}

	# ---------------------------------------------------------------------
	# Status
	# ---------------------------------------------------------------------

	method _status_info () {
		my $tab = $self->active_tab // return ( [ 'F1 keys', 'dim' ] );
		my @parts;
		my $errors = scalar $tab->document->errors;
		push @parts, [ sprintf( '%d error%s', $errors, $errors == 1 ? '' : 's' ), 'danger' ] if $errors;
		push @parts, [ 'modified', 'accent' ] if $tab->is_modified;
		if ( $tab->mode eq 'text' ) {
			my ( $row, $offset ) = $tab->area->editor->cursor;
			push @parts, [ sprintf( 'Ln %d, Col %d', $row + 1, $offset + 1 ), 'info' ];
		}
		push @parts, [ ucfirst( $tab->mode ), 'info' ], [ 'F1 keys', 'dim' ];
		return @parts;
	}

	# The line under the form: what the setting under the cursor is.
	method _explain ($row) {
		my $tab      = $self->active_tab // return '';
		my $document = $self->_shown_document($tab);
		if ( $row->{section} ) {
			my @keys = $form->keys_in( $row->{id} );
			my $set  = grep { defined $document->setting($_) } @keys;
			return sprintf( '[bold]%s[/]: %d of %d settings set. Enter opens or closes it, Delete resets it, Ctrl+C copies what it sets.', _escaped( $row->{setting} ), $set, scalar @keys );
		}
		my $key       = $row->{key};
		my $parsed    = Term::Fabulous::Theme::Document::parse_key($key);
		my $effective = $document->effective_setting($key);
		my $kind
			= $parsed->{section} eq 'palette' ? 'a color'
			: $parsed->{section} eq 'theme'   ? ( $parsed->{field} eq 'name' ? 'the theme\'s name' : 'the built-in theme it starts from' )
			: do {
			my $info = Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} );
			$info->{kind} eq 'boolean'
				? 'true or false'
				: ( $info->{kind} eq 'style' ? 'a border style' : 'a token or a color' ) . ( $info->{required} ? ', required' : '' );
			};
		my $line  = $document->line_of($key);
		my $where = $effective->{origin} eq 'set' ? 'set' . ( defined $line ? " on line $line" : '' ) : 'follows ' . _origin_words($effective);
		return sprintf( '[bold]%s[/] (%s): %s. Enter edits, Delete resets, Ctrl+C copies, Ctrl+V pastes.', _escaped($key), $kind, _escaped($where) );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor - Edit Term::Fabulous themes with a live
preview of every widget

=head1 SYNOPSIS

From the shell, with the program that comes with the distribution:

=for highlighter language=text

	fabulous-theme-editor                        # a new theme
	fabulous-theme-editor themes/ocean.kdl       # edit a theme file
	fabulous-theme-editor themes/*.kdl           # every theme of a folder, one per tab

=for highlighter language=perl

From Perl:

	use Term::Fabulous::ThemeEditor;

	Term::Fabulous::ThemeEditor->new( files => ['themes/ocean.kdl'] )->run;

	# Preview the theme on the screens of your own program:
	Term::Fabulous::ThemeEditor->new(
		files   => ['themes/mine.kdl'],
		preview => sub ($editor) { return build_main_screen() },
	)->run;

	# A program then loads the file:
	my $ui = Term::Fabulous->new( root => $root, theme => Term::Fabulous::Theme->from_file('themes/mine.kdl') );

=head1 DESCRIPTION

The theme editor makes and changes the theme files of
L<Term::Fabulous::Theme>: the KDL files that set the palette of a theme
and the colors, border styles and borders of every widget family. It opens each
theme in a tab of its own. The left side of the screen shows a widget
of every family drawn in the theme of the tab you are on, and you can
try them out: type into the fields, open the dropdown, move the slider,
press the buttons, open the dialog. The right side shows the theme's
settings, either as a form, a list of every setting with its value and
where the value comes from, or as the text of the file. Every change
shows in the preview at once, and every change can be undone.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/example-theme-editor.svg" alt="The theme editor with four themes in tabs: the menu bar, the tab strip with ocean.kdl active, the preview on the left with the palette swatches, text with links and a box in the ocean theme, and the form on the right listing the theme's name and base and the palette tokens with their swatches, values and where they come from, the cursor on accent"></p>

=end html

The picture shows F<examples/theme-editor.pl>, which opens the theme
files of F<examples/themes/>. The editor itself is drawn in its own
theme (the built-in C<dark> unless you choose another), the preview in
the theme being edited, so an unreadable theme never makes the editor
unreadable.

The editor is a L<Term::Fabulous> program like any other. The script
L<fabulous-theme-editor> starts it from the shell; this page describes
the editor and how to start it from Perl.

=head1 THE SCREEN

From top to bottom:

=over

=item The menu bar

C<File>, C<Edit>, C<View>, C<Theme> and C<Help>, with every command
and its keys (a L<Term::Fabulous::Widget::MenuBar>). C<F10> opens the
first menu, C<Alt> with a menu's underlined letter opens that menu
(C<Alt+F> for C<File>), and a click opens a menu with the mouse. Commands that cannot run now (C<Revert>
of a theme without a file, C<Undo> with nothing to undo) are dimmed.

=item The tab strip

A tab per open theme (a L<Term::Fabulous::Widget::DocumentTabs>): its
file's name (C<untitled-N> before it is saved), a dot while it has
unsaved changes or an exclamation mark while its text has errors, and a
close button. A click selects a tab, a click on its close button or a
middle click closes it, the C<+> at the end makes a new theme.

=item The preview (left)

A widget of every family in sections: the palette with a swatch of
every token, text and links, boxes, buttons (one of them with the class
C<primary>), text fields (one with an invalid value, one disabled, a
text area with a scrollbar), check boxes, radio buttons, a segmented
control, a slider, a star rating and a dropdown, a color picker, tabs,
document tabs, an accordion, a
table with groups, a filter row and pages, progress bars and a spinner,
toasts, a menu bar, a menu and status bars, a button that opens a
dialog, dividers, an image, and a sample of every variant the theme
defines. The background behind them is the
theme's C<background> token. The title of the pane says which theme it
shows; while the text of the theme has errors, it shows the theme as it
was before them and says so.

When the cursor of the form moves to a setting, the gallery scrolls to
the section that shows the setting's family. C<F7> hides the preview,
so the settings take the whole width (useful on a narrow terminal), and
shows it again.

=item The settings (right)

The form or the text of the theme; the switch at the top right (or
C<F2>) changes between them, and the other mode opens at the same
setting. The pane that has the keyboard focus has its frame drawn in
the accent color.

=item The status line

What the last action did, in the colors the editor's theme gives
success, warnings and errors, and on the right the number of errors in
the text, whether the theme has unsaved changes, the line and column of
the cursor in text mode, and the mode. A message too long for the line
ends in an ellipsis.

=back

=head1 THE FORM

The form lists every setting a theme can have, in sections: the
C<theme> node (the theme's name and the built-in theme it extends),
the palette (every token), and one section per widget family with every
slot of the family in every state it has (see
L<Term::Fabulous::Theme/VOCABULARY>). A family's section holds a
section for each of its variants, with every slot again. A section
opens with C<Right>, C<+>, C<Enter> or a click on its marker and closes
with C<Left> or C<->; a section row says how many of its settings the
theme sets.

Each row shows four things:

=over

=item a swatch

the color the setting has in the theme, or the corner and edges of its
border style;

=item the setting

the token or the slot and state, as the theme file names them
(C<border.color.focused>); rows the theme sets are bold;

=item the value

a token name (C<accent>), a color (C<#5fd3c0>), a border style
(C<Round>), C<true> or C<false> (C<border.enabled>), C<none> or
C<reverse>;

=item where the value comes from

C<set> when the theme sets it; C<dark> or C<light> for a palette token
the theme leaves to the built-in theme it extends; C<default> for a
slot that has the default of the vocabulary; C<normal> for a state that
looks like the slot's normal state; C<family> for a variant's slot that
follows its family.

=back

A text too long for its column ends in C<~>. The line under the form
explains the setting under the cursor: its kind, whether it is
required, and the line of the file that sets it.

=head2 Changing a setting

C<Enter> or a double click on a setting opens a dialog for its value,
at the right edge of the screen and without dimming the screen behind
it, so the preview shows the value in its true colors:

=over

=item a color slot

a L<Term::Fabulous::Widget::ColorPicker>: a list of the palette's
tokens with their colors (and C<none> where the slot may have no color,
C<reverse> for C<button.background.pressed>), and a color of its own: a
field for C<#rrggbb>, C<#rrggbbaa>, C<rgb(...)>, C<hsl(...)> or a color
name, with a sample, sliders for red, green and blue or (switched with
C<RGB> and C<HSL>) for hue, saturation and lightness, and a slider for
alpha;

=item a palette token

the color picker without the list (a token is a color, never another
token);

=item a border style slot

the border styles with a sample of each (only those with joints for
C<tabs.line.style>), and C<none> where the slot may have none;

=item C<border.enabled>

C<true> and C<false>: whether the widgets of the family have a border
unless the program decides it;

=item C<theme.name> and C<theme.extends>

a field for the name, and the built-in themes to extend.

=back

Every choice shows in the preview while the dialog is open; a state
such as C<focused> or C<hovered> shows on a widget of the preview that
has the focus or is under the pointer (C<F6> goes into the preview).
C<Apply> (or C<Enter> in the list or a field) writes the value to the
theme, C<Reset to default> removes the setting, and C<Cancel> or
C<Escape> leaves the theme as it was. A value the setting cannot take,
or a text in the color field that is no color, is not applied; the
dialog says why. A list in a dialog has its frame in the accent color
while it has the keyboard focus.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/example-theme-editor-dialog.svg" alt="The dialog of button.border.color at the right edge: a color picker with the palette's tokens in a list, danger chosen, a field, an RGB and HSL switch and red, green, blue and alpha sliders for a color of its own; on the left, the preview shows the Cancel button of the bordered row with a red border"></p>

=end html

The picture shows the dialog of C<button.border.color> with C<danger>
chosen in the list: the preview on the left draws the Cancel button's
border in it before the value is applied.

C<Delete> resets the setting under the cursor: the theme no longer
sets it, and it follows what the C<From> column then says (the status
line tells which value that is). On a section, C<Delete> resets every
setting the section sets, after a question. C<Theme> E<gt> C<Reset
whole theme> removes every setting but the name and the base.

=head2 Finding settings

The search field above the form (C<Ctrl+F>) shows only the rows whose
setting, value, origin or full key (such as C<button.border.color>)
contain the text, in any case, with their sections; C<Enter> or
C<Down> goes to the first of them and C<Escape> empties the field. The
check box C<Only set> (C<Alt+L>) shows only the settings the theme
sets.

=head2 Variants

A variant changes some settings of a family for the widgets whose
C<classes> name it (see L<Term::Fabulous::Manual::Looks/Variants and classes>).
C<Theme> E<gt> C<Add variant> asks for the family and the name and
adds a section for the variant; the theme file holds the variant once
one of its settings is set. C<Theme> E<gt> C<Remove variant> removes the
variant under the cursor with everything it sets. The gallery shows a
sample of every variant the theme defines at its end.

=head2 When the text has errors

While the text of the theme has errors, the form shows the last state
of the theme without errors, takes no changes, and a line above it says
how many errors there are; C<F8> shows the first one in text mode.

=head1 THE TEXT

Text mode (C<F2>) shows the theme file as it is, comments and all, in
a text area: the editing keys of
L<Term::Fabulous::Widget::TextArea/KEYS> work, and a few keys help with
KDL (see L</KEYS>): C<Enter> keeps the indentation and indents one
level more after an opening brace; a C<}> typed into the indentation of
a line takes the line back one level; C<Tab> indents the selected lines
or, without a selection, inserts one level of indentation at the
cursor, and C<Shift+Tab> outdents the cursor's line or the selected
lines. A tab in the text is shown two columns wide.

The text is read again when you stop typing for a moment, and the
preview, the form and the error list follow. The first three mistakes
are listed under the text with their line numbers (and how many more
there are), as L<Term::Fabulous::Theme::Document/errors> reports them: a
KDL syntax error at the line where the parser stopped, and every
mistake of the theme (an unknown token, family, slot or state, a value
a slot cannot take, a setting given twice) at the line that holds it.
C<F8> moves to the next error. C<Ctrl+F> finds a text and C<F3> finds
it again.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/example-theme-editor-text.svg" alt="The theme editor in text mode: the end of ocean.kdl with a new line button { text "acent" }, the message Line 51: button.text must be a color, got 'acent' (unrecognized color string 'acent') under the text, an exclamation mark on the tab, and the preview marked stale"></p>

=end html

The form and the text change the same file. A change in the form
rewrites only the lines that hold the setting (or adds it where it
belongs: a slot to its family's block, a state to its state block), so
comments, blank lines, indentation and the order of everything else
stay as you wrote them; see L<Term::Fabulous::Theme::Document>.

=head1 UNDO AND REDO

C<Ctrl+Z> and C<Ctrl+Y> undo and redo every change to a theme, made in
the form or in the text, in one history per tab: a change in the form,
a paste, a reset or a revert is one step; typing is undone a word at a
time. Each tab keeps up to 100 steps. After an undo in form mode, the
cursor goes to the setting that changed.

=head1 COPY AND PASTE

The clipboard holds text, so settings travel between tabs, between the
form and the text mode, and out of the editor in a form you can read.

=over

=item In the form

C<Ctrl+C> copies the setting under the cursor, with the value it has
now, as a piece of a theme file:

=for highlighter language=kdl

	button {
		focused {
			border color="accent"
		}
	}

=for highlighter language=perl

On a section, it copies every setting the section sets (a family's
variants included). C<Ctrl+X> copies and resets. C<Ctrl+V> pastes: a
single copied setting gives its value to the setting under the cursor,
so a color copied from one token or slot can be pasted onto any other;
several settings, or one with the cursor on a section, are set at their
own keys. C<Alt+P> always pastes at the copied keys, which copies a
setting from one theme to the same setting of another. A plain value on
the clipboard (C<#ff8800>, C<accent>, C<Round>) pastes onto the setting
under the cursor, too.

=item In text mode

C<Ctrl+C>, C<Ctrl+X> and C<Ctrl+V> copy, cut and paste text, as in any
text area; settings copied in the form paste as their text.

=back

The clipboard is the one of the text inputs of Term::Fabulous
(L<Term::Fabulous::Editor/clipboard>), not the clipboard of your
desktop.

=head1 FILES

C<Ctrl+S> saves the theme of the tab to its file; a new theme asks
where (as C<Alt+S>, C<Save as>, does; a name without an extension gets
C<.kdl>, and saving over another file that exists asks first).
C<File> E<gt> C<Save all> saves every theme with unsaved changes. A file is written to a temporary file first and then renamed
over the old one, so it is never half written; it keeps its permissions
and its line ends (CRLF when every line of it ended in CRLF), a symbolic
link keeps pointing to its file, and a read-only file is not replaced.
Saving asks first when the theme has errors (a program could not load
it) and when another program changed the file since the editor read
it.

C<Ctrl+O> opens theme files. The open and save dialogs (a
L<Term::Fabulous::Widget::FileDialog>) list the folders and the
C<*.kdl> files of a folder (all files when C<All files> is chosen
instead of C<Theme files>, hidden ones with C<Show hidden files>), and
take a name or a path; a file that is open already shows its tab. A
file with errors opens in text mode. C<Ctrl+R> reverts a theme to its
file (after a question when it has unsaved changes; undo takes it
back). C<Ctrl+N> makes a new theme based on C<dark> or C<light>, and
C<File> E<gt> C<Duplicate as new theme> copies the theme of the tab
into a new, untitled one.

C<Ctrl+W> closes a tab and C<Ctrl+Q> quits; both ask whether to save
unsaved changes first. C<Ctrl+C> does not quit the editor: it copies.
When the editor is ended by a signal (C<TERM>, C<INT>, C<HUP>; not on
Windows, where L<IO::Async> watches no signals), the
text of every theme with unsaved changes is written to C<FILE.unsaved>
(for a new theme, C<untitled-N.kdl.unsaved> in the folder of the
C<directory> parameter, by default the current one), and the files are
listed on the standard error.

=head1 KEYS

C<F1> shows this list in the editor, with a search field (a
L<Term::Fabulous::Widget::KeyReference>). Keys that a
focused widget uses itself (a text field, the text of the theme, a
dialog) do what that widget does; the others reach the editor.

=for highlighter language=text

	Everywhere
	  Ctrl+N               New theme
	  Ctrl+O               Open
	  Ctrl+S               Save
	  Alt+S                Save as
	  Ctrl+R               Revert to saved
	  Ctrl+W               Close tab
	  Ctrl+Q               Quit
	  Ctrl+Z, Ctrl+Y       Undo, redo
	  Ctrl+X, Ctrl+C       Cut, copy
	  Ctrl+V               Paste
	  Ctrl+F, F3           Find, find next
	  F8                   Go to the next error
	  F2                   Form or text
	  F6                   Preview or settings
	  F7                   Show or hide the preview
	  Alt+PageUp           Previous tab
	  Alt+PageDown         Next tab
	  Alt+1 to Alt+9       The first to the ninth tab
	  F1                   Key reference
	  F10                  Open the menu bar
	  Alt+F, Alt+E, Alt+V, Alt+T, Alt+H    Open a menu
	  Tab, Shift+Tab       Move the focus (in text mode: indent, outdent)

	Menus
	  Left, Right, Tab     Another menu
	  Up, Down, Home, End  Another command
	  Enter, Space         Run the command
	  Escape, F10          Close the menu

	The form
	  Up, Down, PageUp, PageDown, Home, End    Move between settings
	  Right, +             Open a section; Right on an open one goes into it
	  Left, -              Close a section; on a setting, go to its section
	  Enter, Space         Edit the setting; open or close a section
	  Delete               Reset the setting, or every setting of a section
	  Ctrl+C, Ctrl+X       Copy (cut) the setting, or what a section sets
	  Ctrl+V               Paste onto the setting, or at the copied keys
	  Alt+P                Paste at the copied keys
	  Alt+L                Show only the settings the theme sets
	  Ctrl+F, Escape       Search the settings; empty the search

	Text mode
	  Enter                New line, indented like the last (more after {)
	  Tab                  Indent the selected lines; without a selection,
	                       insert one level of indentation
	  Shift+Tab            Outdent the line or the selected lines
	  }                    Typed into the indentation: one level back
	  Alt+Backspace        Delete the word before the cursor
	  Ctrl+F, F3, F8       Find, find next, next error
	  (and the keys of a text area: selection, Ctrl+A, Ctrl+U, Ctrl+K, ...)

	The preview
	  F6                   Into the preview, back to the settings
	  Tab, Shift+Tab       Between the widgets
	  PageUp, PageDown     Scroll
	  Ctrl+Home, Ctrl+End  To the top, to the end

	Dialogs
	  Tab, Shift+Tab       Between fields and buttons
	  Enter                Choose (in a list), press the button
	  Escape               Cancel

	Files (the open and save dialogs)
	  Enter                Open a folder, choose a file
	  Backspace            The parent folder

=for highlighter language=perl

Some terminals keep C<F1>, C<F10> or C<Alt> combinations for
themselves. Every command is in a menu, which C<Alt> with the
underlined letter or a click opens too.

=head1 USING THE EDITOR FROM PERL

=head2 Starting it

	use Term::Fabulous::ThemeEditor;

	my $editor = Term::Fabulous::ThemeEditor->new(
		files    => [ 'themes/ocean.kdl', 'themes/new.kdl' ],    # new.kdl is made when saved
		ui_theme => 'light',                                     # the editor's own look
	);
	$editor->run;
	say 'Unsaved work was kept in ', join ', ', $editor->recovered_files if $editor->recovered_files;

C<run> returns when the user quits. The program
F<examples/theme-editor.pl> does the same with the theme files of the
distribution:

=for code-from examples/theme-editor.pl

	# The theme editor with the theme files of examples/themes/, one per tab,
	# as `fabulous-theme-editor examples/themes/*.kdl` would start it. The
	# left side previews the theme of the tab you are on with a widget of
	# every family; the right side edits its settings, as a form or as the
	# text of the file. F1 lists every key, F10 opens the menus, Ctrl+Q
	# quits and asks about unsaved changes first. See
	# Term::Fabulous::ThemeEditor.

	use v5.32;
	use warnings;

	use FindBin;
	use Term::Fabulous::ThemeEditor;

	my @files = sort glob("$FindBin::Bin/themes/*.kdl");
	Term::Fabulous::ThemeEditor->new( files => \@files )->run;

=head2 A preview of your own screens

The gallery shows every family, but a theme is made for a program. Give
the editor the screens of your program with C<preview>, and the left
side shows them, drawn in the theme being edited, live as you change
it. F<examples/cookbook/theme-editor-preview.pl> previews a sign-in
form, with the editor drawn in the light theme:

=for code-from examples/cookbook/theme-editor-preview.pl

	use v5.32;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use Term::Fabulous::ThemeEditor;
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::Checkbox;
	use Term::Fabulous::Widget::Divider;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	# The screen of your program, as the program builds it. No widget here is
	# given a color, so the theme decides them all.
	sub sign_in_screen () {
		my $form = Term::Fabulous::Widget::Box->new(
			bordered => 1,
			layout   => {
				layout_direction => CLAY_TOP_TO_BOTTOM,
				sizing           => { width => sizing_grow( 0, 44 ) },
				padding          => { left  => 1, right => 1 },
				child_gap        => 1,
			},
		);
		my $name     = Term::Fabulous::Widget::TextField->new( placeholder => 'E-mail address', validator => 'email' );
		my $password = Term::Fabulous::Widget::TextField->new( placeholder => 'Password',       mask      => '*' );
		my $sign_in  = Term::Fabulous::Widget::Button->new( classes => ['primary'], bordered => 1, layout => { padding => { left => 1, right => 1 } } );
		$sign_in->add_child( Term::Fabulous::Widget::Text->new( text => 'Sign in' ) );
		my $cancel = Term::Fabulous::Widget::Button->new( bordered => 1, layout => { padding => { left => 1, right => 1 } } );
		$cancel->add_child( Term::Fabulous::Widget::Text->new( text => 'Cancel' ) );
		my $buttons = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
		$buttons->add_child( $sign_in, $cancel );

		$form->add_child(
			Term::Fabulous::Widget::Divider->new( text => 'Sign in', text_position => 'start' ),
			$name, $password,
			Term::Fabulous::Widget::Checkbox->new( label => 'Keep me signed in' ),
			$buttons,
		);
		return $form;
	}

	# The editor shows the screen on its left, in the theme being edited,
	# instead of its gallery of widgets; the editor itself is drawn in the
	# built-in light theme. The theme file is the first argument, or
	# sign-in.kdl in the current directory, which is made when you save.
	Term::Fabulous::ThemeEditor->new(
		files    => [ $ARGV[0] // 'sign-in.kdl' ],
		preview  => sub ($editor) { sign_in_screen() },
		ui_theme => 'light',
	)->run;

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-theme-editor-preview.svg" alt="The theme editor drawn in the light theme, its preview showing a sign-in form in the dark theme being edited: an e-mail field with an invalid address in red, a password field, a check box and Sign in and Cancel buttons; the form on the right lists the palette"></p>

=end html

The widgets of the preview are yours: they can have listeners, change
while the editor runs, and take the keyboard (C<F6> goes into the
preview). Give them no colors of their own where the theme should
decide. The preview scrolls in both directions when it is larger than
its pane, with the mouse wheel and with C<PageUp>, C<PageDown>,
C<Ctrl+Home> and C<Ctrl+End>. Unlike the gallery, it does not scroll to
the family of the setting under the form's cursor.

=head2 Using the theme

The editor writes ordinary theme files. A program loads one with
L<Term::Fabulous::Theme/from_file> and gives it to its UI, or switches
to it at run time:

	my $theme = Term::Fabulous::Theme->from_file('themes/mine.kdl');
	my $ui    = Term::Fabulous->new( root => $root, theme => $theme );
	$ui->theme('light');    # later: another theme

To check or change theme files from a script (in a test of your
distribution, or to make a set of themes that differ in their accent),
use L<Term::Fabulous::Theme::Document>, which the editor uses too:

	use Term::Fabulous::Theme::Document;

	my $document = Term::Fabulous::Theme::Document->read_file('themes/mine.kdl');
	die join "\n", map {"line $_->{line}: $_->{message}"} $document->errors unless $document->is_valid;
	$document->with_setting( 'palette.accent', '#e5c07b' )->write_file('themes/mine-gold.kdl');

=head2 Driving it from a program or a test

The editor runs on any terminal of L<Term::Fabulous>, so a test can
give it a L<Term::Fabulous::Terminal::Memory>, press keys and look at
the screen with L<Term::Fabulous/step>, and every command runs from
Perl by its id (see L</COMMANDS>):

	use Term::Fabulous::Terminal::Memory;
	use Term::Fabulous::ThemeEditor;

	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 120, height => 36 );
	my $editor   = Term::Fabulous::ThemeEditor->new(
		files    => ['ocean.kdl'],
		terminal => $terminal,
		width    => 120,
		height   => 36,
	);
	$editor->set_setting( 'palette.accent', '#ff8800' );
	$terminal->press_key('Ctrl+S');
	$editor->ui->step;    # reads the key: the theme is saved
	print join "\n", $terminal->lines;

=head1 CONSTRUCTOR

=head2 new

	my $editor = Term::Fabulous::ThemeEditor->new(%parameters);

All parameters are optional; unknown parameters die.

=over

=item C<files>

An array reference of theme files, each opened in a tab, in order.
Default: none, which starts with a new theme based on C<dark>. A file
that does not exist becomes a new theme that is written there when it
is saved; a file with errors opens in text mode. A file that cannot be
read, or is not UTF-8 text, dies.

=item C<ui_theme>

The theme the editor itself is drawn in: a L<Term::Fabulous::Theme>
or the name of a built-in theme. Default: C<dark>. The preview always
shows the theme being edited.

=item C<preview>

What the left side shows: a L<Term::Fabulous::Widget> without a parent,
or a code reference that gets the editor and returns one. Default: the
gallery of every widget family. The widget is drawn in the theme being
edited and is put into a scroll box that scrolls in both directions.

=item C<directory>

The folder the Open and Save as dialogs show for a theme without a
file, where new themes are recovered after a signal, and against which
the status line shortens paths. Default: the current directory. A
folder that does not exist dies.

=item C<terminal>, C<width>, C<height>

The terminal to run on and its size before it is opened, as for
L<Term::Fabulous/new>. Default: the real terminal; 80 by 24 until it
tells its size. Tests pass a L<Term::Fabulous::Terminal::Memory>.

=back

=head1 METHODS

=head2 run

	$editor->run;

Runs the editor until the user quits or a signal ends it; returns the
editor. See L</FILES> for what happens to unsaved changes.

=head2 recovered_files

	my @files = $editor->recovered_files;

The files the last L</run> wrote the unsaved text of themes to, because
a signal ended it; empty when it ended normally.

=head2 is_quitting

1 after the user quit (or confirmed quitting), else 0.

=head2 ui

The L<Term::Fabulous> object of the editor (a
L<Term::Fabulous::ThemeEditor::UI>): for L<Term::Fabulous/step> in
tests, or to look at the terminal.

=head2 tabs, active_tab

	foreach my $tab ( $editor->tabs ) {
		printf "%s%s\n", $tab->title, $tab->is_modified ? ' (changed)' : '';
	}

The open themes as L<Term::Fabulous::ThemeEditor::Tab> objects, in the
order of the tab strip, and the one shown (C<undef> when none is open).
A tab knows its C<path>, C<title>, C<text>, C<document> (a
L<Term::Fabulous::Theme::Document>), C<mode> and C<is_modified>.

=head2 select_tab

	$editor->select_tab(0);

Shows the tab with an index (counted from 0; an index past either end
wraps around). Returns 1, or 0 when no tab is open.

=head2 open_file

	my $tab = $editor->open_file('themes/nord.kdl');

Opens a theme file in a new tab, or shows the tab it is open in, and
returns the tab. A file that does not exist becomes a new theme saved
there. Dies when the file cannot be read or is not UTF-8.

The path is a byte string, as the file system has it (as on the command
line and in a L<Term::Fabulous::Widget::FileDialog> answer); a
character string with characters above 255 dies. The editor shows
paths and file names (tab titles, messages) decoded from UTF-8, with a
byte that is no UTF-8 shown as C<\xHH>.

=head2 new_theme

	my $tab = $editor->new_theme( name => 'sunset', extends => 'light' );

A new, untitled theme in a new tab, with a name (default
C<untitled-N>) and a built-in theme to extend (default C<dark>; another
name dies). Returns the tab.

=head2 close_tab

	$editor->close_tab;        # the active tab
	$editor->close_tab(2);

Closes a tab, after a question when it has unsaved changes.

=head2 set_mode

	$editor->set_mode('text');

Shows the active tab as a form (C<form>) or as text (C<text>), at the
place the other mode was at: text mode opens at the line of the setting
under the form's cursor, and the form at the setting on the text
cursor's line (or the nearest one above it). Another mode dies.

=head2 set_setting, reset_setting

	$editor->set_setting( 'button[primary].border.color', 'accent' );
	$editor->reset_setting('palette.accent');

Change a setting of the active tab's theme, as the form does: one undo
step, shown at once, with a message in the status line. The keys and
values are those of L<Term::Fabulous::Theme::Document/Setting keys>.
A value the setting cannot take, and a theme whose text has errors,
change nothing; the status line says why. Both return 1 when the theme
changed, else 0.

=head2 run_command, command_enabled, commands

	$editor->run_command('save');
	say 'can undo' if $editor->command_enabled('undo');
	say "$_->{id}: $_->{label} (@{ $_->{keys} })" foreach $editor->commands;

Run a command by its id as its menu entry would (commands that ask, ask
in a dialog); whether a command can run now; and every command with
its label (without a trailing C<...>) and keys, in the order of the
menus. C<run_command> returns
1 when the command ran, 0 when it could not run now; an unknown id
dies.

=head2 key_list

	foreach my $key ( $editor->key_list ) {
		my ( $where, $keys, $action ) = @$key;
	}

Every key of the editor, as the key reference (C<F1>) lists it.

=head2 form, status

The form (L<Term::Fabulous::ThemeEditor::Form>) and the status line
(L<Term::Fabulous::Widget::StatusBar>), for programs and tests
that look at what the editor shows: C<< $editor->form->go_to($key) >>
puts the cursor on a setting, C<< $editor->status->message >> is the last
message.

=head1 COMMANDS

The ids of L</run_command, command_enabled, commands>, with their menu
entries and keys:

=for highlighter language=text

	File    new           New theme...               Ctrl+N
	        open          Open...                    Ctrl+O
	        save          Save                       Ctrl+S
	        save_as       Save as...                 Alt+S
	        save_all      Save all
	        revert        Revert to saved            Ctrl+R
	        duplicate     Duplicate as new theme
	        close         Close tab                  Ctrl+W
	        quit          Quit                       Ctrl+Q
	Edit    undo          Undo                       Ctrl+Z
	        redo          Redo                       Ctrl+Y
	        cut           Cut                        Ctrl+X
	        copy          Copy                       Ctrl+C
	        paste         Paste                      Ctrl+V
	        paste_keys    Paste at the copied keys   Alt+P
	        edit          Edit value...              Enter (in the form)
	        reset         Reset to default           Delete (in the form)
	        find          Find...                    Ctrl+F
	        find_next     Find next                  F3
	        next_error    Go to the next error       F8
	View    toggle_mode   Form or text               F2
	        switch_pane   Preview or settings        F6
	        toggle_preview  Show or hide the preview  F7
	        only_set      Only set settings          Alt+L
	        open_all      Open all sections
	        close_all     Close all sections
	        previous_tab  Previous tab               Alt+PageUp
	        next_tab      Next tab                   Alt+PageDown
	Theme   rename        Rename theme...
	        rebase        Change base theme...
	        add_variant   Add variant...
	        remove_variant  Remove variant
	        reset_section Reset section...
	        reset_theme   Reset whole theme...
	Help    keys          Key reference              F1
	        about         About

=for highlighter language=perl

=head1 HOW IT WORKS

For people who extend the editor or wonder how it keeps two themes
apart:

=over

=item *

The text of a tab is the one truth about its theme. The form, the
preview and the error list are made from it by
L<Term::Fabulous::Theme::Document>, and a change in the form is a
change of the text (of the lines that differ), made through the text
area's editor, so form and text share one undo history.

=item *

The editor is a subclass of L<Term::Fabulous>,
L<Term::Fabulous::ThemeEditor::UI>, whose
L<theme_for|Term::Fabulous::Render/theme_for> gives the widgets of the
preview (and the dialog and toasts it opens) the theme being edited,
and every other widget the editor's own theme.

=item *

The editor is made with C<< stop_on_ctrl_c =E<gt> 0 >> (see
L<Term::Fabulous/new>), so C<Ctrl+C> copies; and its text area keeps
C<Tab> through C<captures_tab> (see
L<Term::Fabulous::Manual::Events/Keys Term::Fabulous handles itself>).

=back

=head1 SEE ALSO

L<fabulous-theme-editor>, L<Term::Fabulous::Theme>,
L<Term::Fabulous::Theme::Document>,
L<Term::Fabulous::Manual::Looks/THEMES>, L<Term::Fabulous>.

=cut
