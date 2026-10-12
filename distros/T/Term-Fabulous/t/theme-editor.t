use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(blessed);
use IO::Async::Loop;
use IO::Async::OS;
use Term::Fabulous::Editor;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Theme::Document;
use Term::Fabulous::ThemeEditor;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

my $directory = tempdir( CLEANUP => 1 );
my $ocean     = do { local ( @ARGV, $/ ) = ("$FindBin::Bin/../examples/themes/ocean.kdl"); <> };

# A theme file in the temporary directory, with the text of ocean.kdl or
# another.
sub theme_file {
	my ( $name, $text ) = @_;
	my $path = "$directory/$name";
	open my $handle, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
	print {$handle} $text // $ocean;
	close $handle;
	return $path;
}

sub read_file {
	my ($path) = @_;
	return Term::Fabulous::Theme::Document->read_file($path)->text;
}

# An editor on a memory terminal, drawn once, and a function that presses
# keys (names as Term::Fabulous::Event::KeyPress->key_name returns them,
# or "type:TEXT") and draws after each.
sub editor {
	my (%parameters) = @_;
	my $terminal     = Term::Fabulous::Terminal::Memory->new( width => 120, height => 36 );
	my $editor       = Term::Fabulous::ThemeEditor->new( terminal => $terminal, width => 120, height => 36, directory => $directory, %parameters );
	$editor->ui->step;
	my $press = sub (@keys) {
		foreach my $key (@keys) {
			$key =~ /\Atype:(.*)\z/s ? $terminal->type_text($1) : $terminal->press_key($key);
			$editor->ui->step;
		}
		return;
	};
	return ( $editor, $press, $terminal );
}

# The open dialog of a class, or undef.
sub dialog_of {
	my ( $editor, $class ) = @_;
	my ($dialog) = grep { $_->isa($class) && $_->is_open } $editor->ui->root->descendants;
	return $dialog;
}

sub screen {
	my ($terminal) = @_;
	return join "\n", $terminal->lines;
}

subtest 'a new theme, the screen and the separate themes' => sub {
	my ( $editor, $press, $terminal ) = editor();
	is [ map { $_->title } $editor->tabs ], ['untitled-1'], 'without files, an untitled theme';
	my $tab = $editor->active_tab;
	is [ $tab->mode, $tab->is_modified, $tab->document->name, $tab->document->extends ], [ 'form', 0, 'untitled-1', 'dark' ], 'in form mode, unchanged, named and based on dark';
	like screen($terminal), qr/File\s+Edit\s+View\s+Theme\s+Help/, 'the menu bar';
	like screen($terminal), qr/Preview: untitled-1/,               'the preview pane';
	like screen($terminal), qr/Setting\s+Value\s+From/,            'the form';
	is $editor->ui->stop_on_ctrl_c, 0, 'Ctrl+C does not end the editor';
	ref_is $editor->ui->interaction->get_focused_widget, $editor->form->list, 'the form has the focus';

	$editor->open_file( theme_file( 'light.kdl', qq{theme "pale" extends="light"\n} ) );
	my $ui = $editor->ui;
	my ($inside) = grep { $_->isa('Term::Fabulous::Widget::Text') && $ui->is_in_preview($_) } $ui->root->descendants;
	is $inside->text_color,               Term::Fabulous::Theme->builtin('light')->token('text'), 'the preview draws in the edited theme';
	is $editor->form->search->text_color, Term::Fabulous::Theme->builtin('dark')->token('text'),  'the editor in its own theme';
};

subtest 'opening files' => sub {
	my ( $editor, $press ) = editor( files => [ theme_file('ocean.kdl') ] );
	my $tab = $editor->active_tab;
	is [ $tab->title, $tab->mode, $tab->document->setting('palette.accent') ], [ 'ocean.kdl', 'form', '#5fd3c0' ], 'a theme file in a tab';
	ref_is $editor->open_file("$directory/ocean.kdl"), $tab, 'opening it again shows its tab';
	is scalar $editor->tabs, 1, 'and makes no other';

	my $new = $editor->open_file("$directory/fresh.kdl");
	is [ $new->title, $new->is_modified, $new->document->name ], [ 'fresh.kdl', 1, 'fresh' ], 'a missing file becomes a new theme saved there';
	ok !-e "$directory/fresh.kdl", 'which is not written before it is saved';

	my $broken = $editor->open_file( theme_file( 'broken.kdl', "palette {\n\taccent \"#zz\"\n}\n" ) );
	is $broken->mode, 'text', 'a theme with errors opens in text mode';
	like $editor->status->message,          qr/1 error/,                     'and the status line says so';
	like dies { $editor->open_file( [] ) }, qr/open_file needs a file name/, 'open_file checks its argument';
};

subtest 'file names: bytes for the file system, decoded on the screen' => sub {
	my ( $editor, $press, $terminal ) = editor();
	my $tab = $editor->open_file( theme_file("m\xc3\xa9r.kdl") );
	$editor->ui->step;
	is $tab->path, "$directory/m\xc3\xa9r.kdl", 'the tab keeps the path as bytes';
	like screen($terminal), qr/ mér\.kdl /,        'the tab title is decoded';
	like screen($terminal), qr/Opened mér\.kdl\./, 'and so is the message';
	$editor->open_file( theme_file("bad\xff.kdl") );
	$editor->ui->step;
	like screen($terminal),                                               qr/ bad\\xFF\.kdl /,           'a name that is no UTF-8 still shows';
	like dies { $editor->open_file("$directory/caf\x{e9}\x{2615}.kdl") }, qr/as the file system has it/, 'a path of characters dies';

	$editor->new_theme( name => 'süß' );
	$press->('Ctrl+S');
	my $save_as = dialog_of( $editor, 'Term::Fabulous::Widget::FileDialog' );
	is $save_as->typed, 'süß.kdl', 'the save dialog offers the theme name';
	$save_as->choose( $save_as->typed );
	$editor->ui->step;
	ok -f "$directory/s\xc3\xbc\xc3\x9f.kdl", 'and saves it under its UTF-8 name';
};

subtest 'the key reference on a tiny screen' => sub {
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 2, height => 2 );
	my $editor   = Term::Fabulous::ThemeEditor->new( terminal => $terminal, width => 2, height => 2, directory => $directory );
	$editor->ui->step;
	$terminal->press_key('F1');
	ok lives { $editor->ui->step },                                  'F1 opens it without dying' or note $@;
	ok dialog_of( $editor, 'Term::Fabulous::Widget::KeyReference' ), 'it is open';
};

subtest 'editing a setting in the form' => sub {
	my $path = theme_file('ocean.kdl');
	my ( $editor, $press ) = editor( files => [$path] );
	my $tab  = $editor->active_tab;
	my $form = $editor->form;
	$form->go_to('palette.accent');
	$press->('Enter');
	my $dialog = dialog_of( $editor, 'Term::Fabulous::ThemeEditor::ValueDialog' );
	ok $dialog, 'Enter opens the value dialog';
	$press->( 'type:#ff8800', 'Enter' );
	ok !dialog_of( $editor, 'Term::Fabulous::ThemeEditor::ValueDialog' ), 'Enter in the field applies and closes';
	is $tab->document->setting('palette.accent'), '#ff8800', 'the theme has the new value';
	my @changed = grep { $_ ne '' } map { $_->[0] ne $_->[1] ? $_->[1] : '' } map { [ ( split /\n/, $ocean )[$_], ( split /\n/, $tab->text )[$_] ] } 0 .. 40;
	is \@changed,                                   ["\taccent \"#ff8800\""], 'the text changed in that line only';
	is $editor->ui->preview_theme->token('accent'), [ 255, 136, 0, 255 ],     'the preview shows it';
	ok $tab->is_modified, 'the tab has unsaved changes';

	$press->('Ctrl+Z');
	is $tab->document->setting('palette.accent'), '#5fd3c0', 'Ctrl+Z undoes the change';
	is $tab->text,                                $ocean,    'to the text it was';
	ok !$tab->is_modified, 'which is the saved one';
	$press->('Ctrl+Y');
	is $tab->document->setting('palette.accent'), '#ff8800', 'Ctrl+Y redoes it';

	$form->go_to('button.border.color.focused');
	$press->('Enter');
	ok dialog_of( $editor, 'Term::Fabulous::ThemeEditor::ValueDialog' ), 'a slot opens the dialog too';
	$press->( 'Down', 'Escape' );
	is $tab->document->setting('button.border.color.focused'),                  undef,                                                            'Escape leaves the theme as it was';
	is $editor->ui->preview_theme->look( 'button', 'border.color', 'focused' ), $tab->preview_theme->look( 'button', 'border.color', 'focused' ), 'and the preview too';
	$form->go_to('text_input.border.enabled');
	$press->('Enter');
	ok dialog_of( $editor, 'Term::Fabulous::ThemeEditor::ValueDialog' ), 'a boolean slot opens the dialog';
	$press->( 'Up', 'Enter' );
	is $tab->document->setting('text_input.border.enabled'), 'true', 'the list chooses true';
	like $tab->text, qr/enabled=#true/, 'which the file holds as #true';
	is $editor->ui->preview_theme->look( 'text_input', 'border.enabled' ), 1, 'and the preview frames text fields';
};

subtest 'resetting settings' => sub {
	my ( $editor, $press ) = editor( files => [ theme_file('ocean.kdl') ] );
	my $tab = $editor->active_tab;
	$editor->form->go_to('palette.accent');
	$press->('Delete');
	is $tab->document->setting('palette.accent'), undef, 'Delete resets a set setting';
	like $editor->status->message, qr/follows the dark theme \(#61afef\)/, 'the status line says what it follows now';
	$press->('Delete');
	like $editor->status->message, qr/is not set/, 'Delete on an unset one says so';

	$editor->form->go_to( Term::Fabulous::ThemeEditor::Form::section_id( 'family', 'divider' ) );
	$press->('Delete');
	my $prompt = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	ok $prompt, 'Delete on a section asks first';
	$prompt->answer('reset');
	$editor->ui->step;
	is $tab->document->setting('divider.line.style'), undef, 'and resets what the section sets';
	unlike $tab->text, qr/Dividers draw/, 'with the comment above it';
};

subtest 'copy and paste between themes' => sub {
	my ( $editor,    $press )     = editor( files => [ theme_file('ocean.kdl'), theme_file( 'plain.kdl', qq{theme "plain"\n} ) ] );
	my ( $ocean_tab, $plain_tab ) = $editor->tabs;
	$editor->select_tab(0);
	$editor->form->go_to('palette.accent');
	$press->('Ctrl+C');
	like( Term::Fabulous::Editor->clipboard, qr/palette \{\n\taccent "#5fd3c0"\n\}/, 'Ctrl+C copies the setting as KDL' );

	$editor->select_tab(1);
	$editor->form->go_to('palette.danger');
	$press->('Ctrl+V');
	is $plain_tab->document->setting('palette.danger'), '#5fd3c0', 'Ctrl+V pastes one value onto the setting under the cursor';
	$press->('Alt+P');
	is $plain_tab->document->setting('palette.accent'), '#5fd3c0', 'Alt+P pastes at the key it was copied from';

	$editor->select_tab(0);
	$editor->form->go_to( Term::Fabulous::ThemeEditor::Form::section_id( 'family', 'button' ) );
	$press->('Ctrl+C');
	$editor->select_tab(1);
	$press->('Ctrl+V');
	is $plain_tab->document->setting('button[primary].border.color'), 'accent',                    'a copied section pastes at its keys, variants included';
	is [ $plain_tab->document->variants ],                            [ [ 'button', 'primary' ] ], 'so the variant exists there now';

	Term::Fabulous::Editor->clipboard('#123456');
	$editor->form->go_to('palette.text');
	$press->('Ctrl+V');
	is $plain_tab->document->setting('palette.text'), '#123456', 'a plain color pastes onto the setting';
	Term::Fabulous::Editor->clipboard('not a theme at all');
	$press->('Ctrl+V');
	like $editor->status->message, qr/no theme settings/, 'other text is no setting';

	$press->('Ctrl+X');
	is $plain_tab->document->setting('palette.text'), undef, 'Ctrl+X copies and resets';
};

subtest 'text mode' => sub {
	my ( $editor, $press ) = editor( files => [ theme_file('ocean.kdl') ] );
	my $tab = $editor->active_tab;
	$press->('F2');
	is $tab->mode, 'text', 'F2 switches to text mode';
	ref_is $editor->ui->interaction->get_focused_widget, $tab->area, 'the text has the focus';

	my $editor_of_text = $tab->area->editor;
	$editor_of_text->move_document_end;
	$tab->area->mark_changed;
	$press->( 'Enter', 'type:button {', 'Enter' );
	is( ( $editor_of_text->lines )[-1], "\t", 'Enter indents after an opening brace' );
	$press->( 'type:text "warning"', 'Enter', 'type:}' );
	is [ ( $editor_of_text->lines )[ -2, -1 ] ],             [ "\ttext \"warning\"", '}' ],           'a closing brace goes back a level';
	is $tab->document->setting('button.text'),               'warning',                               'the typed text is parsed';
	is $editor->ui->preview_theme->look( 'button', 'text' ), $tab->document->theme->token('warning'), 'and the preview follows';

	$press->( 'Home', 'Tab' );
	ref_is $editor->ui->interaction->get_focused_widget, $tab->area, 'Tab stays in the text';
	is( ( $editor_of_text->lines )[-1], "\t}", 'and indents' );
	$press->('BackTab');
	is( ( $editor_of_text->lines )[-1], '}', 'Shift+Tab outdents' );

	$press->( 'End', 'Enter' );
	my $valid = $editor->ui->preview_theme;
	$press->('type:wat');
	my $line = $editor_of_text->line_count;
	ok $tab->is_stale, 'a mistake makes the preview stale';
	is [ map { $_->{line} } $tab->document->errors ], [$line], 'with the error on its line';
	ref_is $editor->ui->preview_theme, $valid, 'the preview keeps the last valid theme';
	$press->('F2');
	ok $editor->form->read_only, 'the form shows it read-only';
	$press->('F8');
	is [ $tab->mode, ( $editor_of_text->cursor )[0] ], [ 'text', $line - 1 ], 'F8 goes to the error in text mode';
	$press->( 'Ctrl+Z', 'Ctrl+Z' );
	ok $tab->document->is_valid, 'undo takes the mistake back';
};

subtest 'saving, reverting, closing' => sub {
	my $path = theme_file('ocean.kdl');
	my ( $editor, $press ) = editor( files => [$path] );
	my $tab = $editor->active_tab;
	$editor->set_setting( 'palette.text', '#fafafa' );
	$press->('Ctrl+S');
	like read_file($path), qr/\ttext "#fafafa"/, 'Ctrl+S writes the file';
	ok !$tab->is_modified, 'the tab is saved';

	$editor->set_setting( 'palette.text', '#000000' );
	$press->('Ctrl+R');
	dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' )->answer('revert');
	$editor->ui->step;
	is $tab->document->setting('palette.text'), '#fafafa', 'Ctrl+R reverts to the file after asking';

	$tab->change_text( $tab->text . "wat\n" );
	$press->('Ctrl+S');
	my $question = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	ok $question, 'a theme with errors is saved only after a question';
	$question->answer('cancel');
	$editor->ui->step;
	unlike read_file($path), qr/wat/, 'cancelled, nothing is written';
	$tab->undo;

	open my $other, '>>', $path or die;
	print {$other} "// changed elsewhere\n";
	close $other;
	utime time, time + 5, $path;
	$editor->set_setting( 'palette.text', '#111111' );
	$press->('Ctrl+S');
	my $changed = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	ok $changed, 'a file changed on the disk is overwritten only after a question';
	$changed->answer('save');
	$editor->ui->step;
	like read_file($path), qr/#111111/, 'then it is';

	$editor->new_theme;
	$editor->set_setting( 'palette.accent', '#abcdef' );
	$press->('Ctrl+S');
	my $save_as = dialog_of( $editor, 'Term::Fabulous::Widget::FileDialog' );
	ok $save_as, 'an untitled theme is saved where the user says';
	$save_as->choose('sunrise');
	$editor->ui->step;
	is $editor->active_tab->path, File::Spec->catfile( $directory, 'sunrise.kdl' ), 'with .kdl added to a name without one';
	like read_file("$directory/sunrise.kdl"), qr/accent "#abcdef"/, 'and written';

	$editor->set_setting( 'palette.accent', '#fedcba' );
	$press->('Ctrl+W');
	my $close = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	ok $close, 'closing a tab with unsaved changes asks';
	$close->answer('discard');
	$editor->ui->step;
	is [ map { $_->title } $editor->tabs ], ['ocean.kdl'], 'and closes it without saving';
	$press->('Ctrl+W');
	is [ $editor->tabs ], [], 'a saved tab closes at once';
	like join( "\n", $editor->ui->terminal->lines ), qr/No theme is open/, 'and the editor says what to do';
};

subtest 'quitting' => sub {
	my ( $editor, $press ) = editor( files => [ theme_file('ocean.kdl') ] );
	$press->('Ctrl+Q');
	ok $editor->is_quitting, 'Ctrl+Q quits at once without unsaved changes';

	( $editor, $press ) = editor( files => [ theme_file('ocean.kdl') ] );
	$editor->set_setting( 'palette.text', '#000000' );
	$press->('Ctrl+Q');
	ok !$editor->is_quitting, 'with unsaved changes it asks';
	my $prompt = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	$prompt->answer('discard');
	ok $editor->is_quitting, 'and quits without saving when told so';
};

subtest 'menus and help' => sub {
	my ( $editor, $press ) = editor();
	$press->('F10');
	my ($menu) = grep { $_->isa('Term::Fabulous::Widget::MenuBar') } $editor->ui->root->descendants;
	is $menu->open_menu, 0, 'F10 opens the first menu';
	$press->( 'Right', 'Right' );
	is $menu->open_menu, 2, 'Right moves to the next menu';
	$press->('Escape');
	ok !$menu->is_open, 'Escape closes it';
	ref_is $editor->ui->interaction->get_focused_widget, $editor->form->list, 'and the focus goes back';

	$press->('Alt+V');
	is $menu->open_menu, 2, 'Alt with a letter opens its menu';
	$press->('Enter');
	ok !$menu->is_open, 'Enter runs the command';
	is $editor->active_tab->mode, 'text', 'here View > Form or text';

	$press->('F1');
	my $keys = dialog_of( $editor, 'Term::Fabulous::Widget::KeyReference' );
	ok $keys, 'F1 opens the key reference';
	ok( ( grep { $_->[1] eq 'Ctrl+S' && $_->[2] eq 'Save' } $editor->key_list ), 'which lists every key' );
	my $table  = $keys->table;
	my @listed = map { my $row = $table->row($_); [ $row->{group} =~ s/\A\d+ //r, $row->{keys}, $row->{action} ] } $table->filtered_row_ids;    # a group's value starts with its rank
	is \@listed, [ $editor->key_list ], 'the reference built from the commands lists the rows of key_list';
	$press->('Escape');
	ok !dialog_of( $editor, 'Term::Fabulous::Widget::KeyReference' ), 'Escape closes it';
};

subtest 'views: the place in both modes, only set, the preview hidden' => sub {
	my ( $editor, $press, $terminal ) = editor( files => [ theme_file('ocean.kdl') ] );
	my $tab = $editor->active_tab;
	$editor->form->go_to('palette.danger');
	$press->('F2');
	is( ( $tab->area->editor->cursor )[0] + 1, $tab->document->line_of('palette.danger'), 'F2 opens the text at the line of the setting' );
	$tab->area->editor->move_to( $tab->document->line_of('divider.line.style') - 1, 3 );
	$press->('F2');
	is $editor->form->current_key, 'divider.line.style', 'and the form at the setting of the text line';

	$press->('Alt+L');
	ok $editor->form->only_set->checked, 'Alt+L shows only the settings the theme sets';
	is [ grep { !/\A#/ && !defined $tab->document->setting($_) } $editor->form->list->filtered_row_ids ], [], 'and no other';
	$press->('Alt+L');
	ok !$editor->form->only_set->checked, 'and back';

	$press->('F7');
	unlike screen($terminal), qr/Preview:/, 'F7 hides the preview';
	$press->('F7');
	like screen($terminal), qr/Preview: ocean/, 'and shows it again';
};

subtest 'variants' => sub {
	my ( $editor, $press ) = editor();
	my $tab = $editor->active_tab;
	$editor->form->go_to( Term::Fabulous::ThemeEditor::Form::section_id( 'family', 'button' ) );
	$editor->run_command('add_variant');
	my $prompt = dialog_of( $editor, 'Term::Fabulous::Widget::Prompt' );
	is $prompt->values->{family}, 'button', 'the family under the cursor is suggested';
	$prompt->input('name')->value('danger');
	$prompt->answer('add');
	$editor->ui->step;
	ok $editor->form->has_row('button[danger].text'), 'a new variant shows in the form';
	is [ $tab->document->variants ], [], 'without settings it is not in the file yet';
	$editor->set_setting( 'button[danger].text', 'danger' );
	is [ $tab->document->variants ], [ [ 'button', 'danger' ] ], 'the first setting writes it';
	$editor->form->go_to('button[danger].text');
	$editor->run_command('remove_variant');
	is [ $tab->document->variants ], [], 'Remove variant takes it out';
};

subtest 'recovery after a signal' => sub {
	skip_all 'IO::Async watches no signals on Windows' unless IO::Async::OS->HAVE_SIGNALS;
	my $path = theme_file('ocean.kdl');
	my ( $editor, $press ) = editor( files => [$path] );
	$editor->set_setting( 'palette.text', '#222222' );
	IO::Async::Loop->new->later( sub { kill 'TERM', $$ } );
	like warning { $editor->run }, qr/stopped with unsaved changes; they were written to:\n  \Q$path.unsaved\E\n/, 'and says where';
	is [ $editor->recovered_files ], ["$path.unsaved"], 'TERM ends the editor and keeps unsaved work in FILE.unsaved';
	like read_file("$path.unsaved"), qr/#222222/, 'with the unsaved text';
	unlike read_file($path),         qr/#222222/, 'the file itself is untouched';
};

subtest 'a preview of the program\'s own' => sub {
	my $label = Term::Fabulous::Widget::Text->new( text => 'My screen' );
	my $box   = Term::Fabulous::Widget::Box->new;
	$box->add_child($label);
	my ( $editor, $press, $terminal ) = editor( preview => sub ($editor) { return $box } );
	like screen($terminal), qr/My screen/, 'the preview shows the widgets the program gave';
	ok $editor->ui->is_in_preview($label), 'drawn in the edited theme';
	like dies { Term::Fabulous::ThemeEditor->new( preview => 'nope', terminal => Term::Fabulous::Terminal::Memory->new( width => 80, height => 24 ) ) }, qr/preview must be a Term::Fabulous::Widget/,
		'anything else dies';
};

done_testing;
