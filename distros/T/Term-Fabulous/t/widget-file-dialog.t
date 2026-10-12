use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow);
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::FileDialog;
use Term::Fabulous::Widget::TextField;

my $FileDialog = 'Term::Fabulous::Widget::FileDialog';

# A folder with files of several kinds, a folder, a hidden file and a
# hidden folder.
my $top = abs_path( tempdir( CLEANUP => 1 ) );
make_path( "$top/notes", "$top/.cache", "$top/docs" );
foreach my $file (qw(todo.txt Plan.TXT readme.md theme.kdl .profile notes/old.txt)) {
	open my $handle, '>', "$top/$file" or die "cannot write $top/$file: $!";
	print {$handle} "$file\n";
	close $handle;
}

my $root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $behind   = Term::Fabulous::Widget::TextField->new( value => 'behind' );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 80, height => 30 );
my $ui       = Term::Fabulous->new( width => 80, height => 30, root => $root, terminal => $terminal );
$root->add_child($behind);
$ui->interaction->set_focused_widget($behind);
$ui->step;

sub keys_ (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub focused () {
	return $ui->interaction->get_focused_widget;
}

# The dialog a widget is in, the innermost one.
sub dialog_around ($widget) {
	while ( defined $widget ) {
		return $widget if $widget->isa('Term::Fabulous::Widget::Dialog');
		$widget = $widget->parent;
	}
	return undef;
}

sub descendants ($widget) {
	return map { ( $_, $_->can('children') ? descendants($_) : () ) } @{ $widget->children };
}

sub names ($dialog) {
	return [ map { $_->{name} } @{ $dialog->list->rows } ];
}

# Opens a file dialog and records its answers.
sub opened (%params) {
	my $dialog = $FileDialog->new( directory => $top, %params );
	my @answers;
	$dialog->on( Answer => sub ($event) { push @answers, { button => $event->button, values => $event->values, dismissed => $event->dismissed }; return } );
	$dialog->open($ui);
	$ui->step;
	return ( $dialog, \@answers );
}

subtest 'filters: globs without case, separated by spaces, switched by the dropdown' => sub {
	my ( $dialog, $answers ) = opened( filters => [ [ 'Text files' => '*.txt *.md' ], [ 'All files' => '*' ] ] );
	is $dialog->list->id, $dialog->id . '/list',                              'the list has an id made from the dialog id';
	is names($dialog),    [qw(../ docs/ notes/ Plan.TXT readme.md todo.txt)], 'folders first, then the files the first filter lets through';
	is $dialog->filter,   'Text files',                                       'the first filter is active';

	keys_( 'Tab', 'Tab', 'Enter', 'Down', 'Enter' );
	is $dialog->filter, 'All files',                                                  'the dropdown picks another filter';
	is names($dialog),  [qw(../ docs/ notes/ Plan.TXT readme.md theme.kdl todo.txt)], 'and the folder is listed again';
	like dies { $dialog->filter('Pictures') }, qr/no filter labelled 'Pictures'/, 'an unknown filter dies';
	$dialog->close;

	my ($single) = opened( filters => [ [ 'Themes' => '*.KDL' ] ] );
	is names($single),                                                                [qw(../ docs/ notes/ theme.kdl)], 'one filter applies';
	is [ grep { $_->isa('Term::Fabulous::Widget::Dropdown') } descendants($single) ], [],                               'but shows no dropdown';
	$single->close;
};

subtest 'hidden files show only when asked' => sub {
	my ($dialog) = opened();
	ok !( grep { /\A\./ && $_ ne '../' } @{ names($dialog) } ), 'no dot files at first';
	keys_( 'Tab', 'Tab', 'Space' );
	ok $dialog->show_hidden, 'the checkbox shows them';
	is names($dialog), [qw(../ .cache/ docs/ notes/ .profile Plan.TXT readme.md theme.kdl todo.txt)], 'hidden folders and files are listed';
	$dialog->show_hidden(0);
	is names($dialog), [qw(../ docs/ notes/ Plan.TXT readme.md theme.kdl todo.txt)], 'and go again';
	$dialog->close;
};

subtest 'Cancel and Escape answer cancel' => sub {
	my ( $dialog, $answers ) = opened();
	keys_( 'Tab', 'Tab', 'Tab', 'Tab', 'Enter' );
	ok !$dialog->is_open, 'the Cancel button closes the dialog';
	is $answers, [ { button => 'cancel', values => {}, dismissed => 0 } ], 'and answers cancel, not dismissed';
	ref_is focused(), $behind, 'the focus is back behind';

	$dialog->open($ui);
	keys_('Escape');
	is $answers->[1], { button => 'cancel', values => {}, dismissed => 1 }, 'Escape answers cancel, dismissed';
};

subtest 'open: Enter on a file, a missing file, Backspace and ~' => sub {
	my ( $dialog, $answers ) = opened( directory => "$top/notes" );
	keys_('Backspace');
	is $dialog->directory, $top, 'Backspace in the list goes to the parent folder';

	$dialog->choose('nothing.txt');
	ok $dialog->is_open, 'a missing file keeps the dialog open';
	is $dialog->children->[-2]->text, 'There is no file nothing.txt in this folder.', 'and says so above the buttons, naming what was typed';

	{
		local $ENV{HOME} = "$top/notes";
		$dialog->choose('~/old.txt');
	}
	is $answers, [ { button => 'open', values => { path => File::Spec->catfile( $top, 'notes', 'old.txt' ) }, dismissed => 0 } ], 'a path with ~ starts in the home folder';

	( $dialog, $answers ) = opened();
	keys_( 'Down', 'Down', 'Down', 'Down' );
	is $dialog->typed, 'readme.md', 'the cursor on a file puts its name into the field';
	keys_('Enter');
	is $answers->[0]{values}{path}, File::Spec->catfile( $top, 'readme.md' ), 'Enter on a file opens it, with an absolute path';

	( $dialog, $answers ) = opened( directory => "$top/notes" );
	keys_( 'Down', 'Up' );
	is $dialog->typed, 'old.txt', 'the cursor puts a file name into the field';
	keys_('Enter');
	is $dialog->directory, $top, 'Enter on ../ goes up';
	is $dialog->typed,     '',   'and empties the field';
	keys_( 'Down', 'Down', 'Down', 'Down', 'Up', 'Up', 'Enter' );
	is $dialog->directory, "$top/notes", 'Enter on a folder opens it';
	is $dialog->typed,     '',           'and empties the field';
	keys_( 'Down', 'Backspace' );
	is $dialog->typed, '', 'so does Backspace';
	$dialog->close;
};

subtest 'folder mode' => sub {
	foreach my $meaningless ( [ filters => [] ], [ default_extension => 'txt' ], [ name => 'x' ], [ confirm_overwrite => 0 ] ) {
		like dies { $FileDialog->new( mode => 'folder', @$meaningless ) }, qr/a folder dialog takes no $meaningless->[0]/, "dies with $meaningless->[0]";
	}

	my ( $dialog, $answers ) = opened( mode => 'folder', show_hidden => 1 );
	is names($dialog), [qw(../ .cache/ docs/ notes/)], 'only folders are listed';
	keys_('Down');
	is $dialog->typed, '.cache', 'the cursor on a folder puts its name into the field';
	keys_('Up');
	is $dialog->typed, '', 'and on ../ empties it';

	$dialog->choose('missing');
	is $dialog->children->[-2]->text, 'There is no folder missing in this folder.', 'a missing folder is a message';
	$dialog->choose('notes');
	is $answers, [ { button => 'choose', values => { path => "$top/notes" }, dismissed => 0 } ], 'Choose answers the folder in the field';

	( $dialog, $answers ) = opened( mode => 'folder' );
	keys_( 'Down', 'Down' );
	is $dialog->typed, 'notes', 'the cursor on notes/ puts notes into the field';
	keys_('Enter');
	is $dialog->directory, "$top/notes", 'Enter on a folder opens it';
	is $dialog->typed,     '',           'and empties the field';
	keys_('Backspace');
	is $dialog->typed, '', 'Backspace leaves it empty';
	keys_( 'Down', 'Down', 'Enter' );
	$dialog->choose( $dialog->typed );
	is $answers->[0]{values}{path}, "$top/notes", 'Choose with the field as it is answers the folder shown';

	( $dialog, $answers ) = opened( mode => 'folder' );
	my ($header) = grep { /Name\s+Modified/ } $terminal->lines;
	ok defined $header && $header !~ /Size/, 'the list has no Size column';
	ok( ( grep { /Name A folder name or a path/ } $terminal->lines ), 'and the field is labelled Name' );
	$dialog->close;
};

subtest 'save: the default extension and a missing folder' => sub {
	my ( $dialog, $answers ) = opened( mode => 'save', default_extension => 'txt', name => 'draft' );
	is $dialog->typed, 'draft', 'the field starts with the name';
	$dialog->choose('nowhere/draft');
	is $dialog->children->[-2]->text, 'There is no folder nowhere in this folder.', 'a missing folder is a message';
	$dialog->choose("$top/nowhere/draft");
	is $dialog->children->[-2]->text, "There is no folder $top/nowhere.", 'an absolute path is named as typed';
	$dialog->choose('draft');
	is $answers, [ { button => 'save', values => { path => File::Spec->catfile( $top, 'draft.txt' ) }, dismissed => 0 } ], 'a name without a dot gets the default extension';
};

subtest 'save: a name that becomes a folder with the extension' => sub {
	my $folder = abs_path( tempdir( CLEANUP => 1 ) );
	make_path("$folder/archive.kdl");
	my ( $dialog, $answers ) = opened( mode => 'save', directory => $folder, default_extension => 'kdl' );
	$dialog->choose('archive');
	is $dialog->children->[-2]->text, 'archive.kdl is a folder.', 'is a message, not the Replace question';
	ok $dialog->is_open, 'the dialog stays open';
	is $answers, [], 'and does not answer';
	ref_is dialog_around( focused() ), $dialog, 'no question opened above it';
	$dialog->close;
};

subtest 'save: the question before a file is replaced' => sub {
	my ( $dialog, $answers ) = opened( mode => 'save', current_file => "$top/todo.txt" );
	$dialog->choose('todo.txt');
	is $answers->[0]{values}{path}, File::Spec->catfile( $top, 'todo.txt' ), 'the current file is saved without a question';

	( $dialog, $answers ) = opened( mode => 'save', confirm_overwrite => 0 );
	$dialog->choose('todo.txt');
	is scalar @$answers, 1, 'confirm_overwrite => 0 asks nothing';

	foreach my $case ( [ 'another file' => "$top/readme.md" ], [ 'an untitled file' => undef ] ) {
		my ( $name, $current ) = @$case;
		( $dialog, $answers ) = opened( mode => 'save', current_file => $current );
		$dialog->choose('todo.txt');
		$ui->step;
		my $question = dialog_around( focused() );
		ok $question->isa('Term::Fabulous::Widget::Prompt'), "saving $name over an existing one asks";
		is $question->z_index, $dialog->z_index + 1, 'above the file dialog';
		ref_is focused(), $question->button('cancel'), 'starting on Cancel';
		keys_('Enter');
		ok $dialog->is_open, 'Enter there keeps the file dialog open';
		is $answers, [], 'without an answer';

		$dialog->choose('todo.txt');
		$ui->step;

		keys_('Escape');
		ok $dialog->is_open, 'Escape on the question keeps the file dialog open';
		ref_is dialog_around( focused() ), $dialog, 'with the focus inside it';
		is $answers, [], 'and no answer';

		$dialog->choose('todo.txt');
		$ui->step;
		keys_( 'BackTab', 'Enter' );
		ok !$dialog->is_open, 'Replace closes the file dialog';
		is $answers, [ { button => 'save', values => { path => File::Spec->catfile( $top, 'todo.txt' ) }, dismissed => 0 } ], 'which answers once';
		ref_is focused(), $behind, 'and the focus is back behind both';
	}
};

subtest 'save: the field keeps the name typed' => sub {
	my ( $dialog, $answers ) = opened( mode => 'save', name => 'draft.txt', directory => "$top/notes" );
	ok focused()->isa('Term::Fabulous::Widget::TextField'), 'save mode starts in the field';
	keys_( 'x', 'y' );
	is $dialog->typed, 'xy.txt', 'with the name selected up to its extension';
	keys_( 'BackTab', 'Down', 'Up' );
	is $dialog->typed, 'xy.txt', 'the cursor on a file leaves the name alone';
	keys_('Enter');
	is $dialog->directory, $top,     'Enter on ../ goes up';
	is $dialog->typed,     'xy.txt', 'and the name stays';
	keys_( 'Down', 'Down', 'Down', 'Down', 'Down', 'Down', 'Down', 'Down', 'Enter' );
	is $dialog->typed, 'todo.txt', 'Enter on a file puts its name into the field';
	ok dialog_around( focused() )->isa('Term::Fabulous::Widget::Prompt'), 'and asks before it is replaced';
	keys_('Escape');
	$dialog->close;
};

subtest 'closing the dialog from the program closes the Replace question' => sub {
	my ( $dialog, $answers ) = opened( mode => 'save' );
	$dialog->choose('todo.txt');
	$ui->step;
	my $question = dialog_around( focused() );
	ok $question->isa('Term::Fabulous::Widget::Prompt'), 'the question is open';
	$dialog->close;
	$ui->step;
	ok !$question->is_open, 'closing the file dialog closes it too';
	is $answers, [ { button => 'cancel', values => {}, dismissed => 1 } ], 'the file dialog answers cancel once';
	ref_is focused(), $behind, 'and the focus is back behind both';
};

subtest 'names that are UTF-8 and names that are not' => sub {
	my $folder = abs_path( tempdir( CLEANUP => 1 ) ) . "/caf\xc3\xa9";
	make_path($folder);
	foreach my $file ( "na\xc3\xafve.txt", "bad\xff.txt" ) {
		open my $handle, '>', "$folder/$file" or die "cannot write $folder/$file: $!";
		close $handle;
	}
	like dies { $FileDialog->new( directory => "/tmp/caf\x{e9}\x{2615}" ) }, qr/directory must be bytes/, 'a directory of characters dies';

	my ( $dialog, $answers ) = opened( directory => $folder );
	is $dialog->directory, $folder,                                     'directory is bytes';
	is names($dialog),     [ '../', "bad\\xFF.txt", "na\x{ef}ve.txt" ], 'names are decoded, a byte that is no UTF-8 shows as \\xHH';
	ok( ( grep { /Folder: .*caf\x{e9}/ } $terminal->lines ), 'the folder line shows the folder decoded' );
	keys_('Down');
	is $dialog->typed, "bad\\xFF.txt", 'the field gets the name as shown';
	$dialog->choose( $dialog->typed );
	is $answers->[0]{values}{path}, File::Spec->catfile( $folder, "bad\xff.txt" ), 'and the answer is the name as the file system has it';

	( $dialog, $answers ) = opened( directory => $folder );
	$dialog->choose("na\x{ef}ve.txt");
	is $answers->[0]{values}{path}, File::Spec->catfile( $folder, "na\xc3\xafve.txt" ), 'a typed name is encoded to UTF-8';

	( $dialog, $answers ) = opened( mode => 'save', directory => $folder, name => "r\xc3\xa9sum\xc3\xa9.txt", current_file => "$folder/na\xc3\xafve.txt" );
	is $dialog->typed, "r\x{e9}sum\x{e9}.txt", 'name is bytes, shown decoded';
	$dialog->choose( $dialog->typed );
	is $answers->[0]{values}{path}, File::Spec->catfile( $folder, "r\xc3\xa9sum\xc3\xa9.txt" ), 'and saved as UTF-8 bytes';
	( $dialog, $answers ) = opened( mode => 'save', directory => $folder, current_file => "$folder/na\xc3\xafve.txt" );
	$dialog->choose("na\x{ef}ve.txt");
	is $answers->[0]{values}{path}, File::Spec->catfile( $folder, "na\xc3\xafve.txt" ), 'current_file is bytes too: saving to it asks nothing';
};

subtest 'small screens' => sub {
	open my $handle, '>', "$top/docs/" . ( 'a-very-long-name-' x 4 ) . '.txt' or die "cannot write: $!";
	close $handle;
	my $small_root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $small_terminal = Term::Fabulous::Terminal::Memory->new( width => 50, height => 16 );
	my $small          = Term::Fabulous->new( width => 50, height => 16, root => $small_root, terminal => $small_terminal );
	$small->step;
	my $dialog = $FileDialog->new( directory => "$top/docs" )->open($small);
	$small->step;
	my @lines = $small_terminal->lines;
	ok( ( grep { /Open a file/ } @lines ),                       'the title shows on a 50x16 screen' );
	ok( ( grep { /\x{2502} Open \x{2502}/ } @lines ),            'and so do the buttons' );
	ok( ( grep { /Name\s+Size\s+Modified/ } @lines ),            'a long name leaves room for the size and the time' );
	ok( ( grep { /\.\.\.[a-z-]*\.txt\s+0 B\s+\d{4}-/ } @lines ), 'it is cut from the left' );

	my $height = $small->bounding_box($dialog)->{height};
	$dialog->choose('nothing.txt');
	$small->step;
	is $small->bounding_box($dialog)->{height}, $height, 'a message does not change the height of the dialog';
	$dialog->close;
};

subtest 'on a narrow screen the folder line keeps the end of the path' => sub {
	my $deep = "$top/docs/" . join '/', ('a-rather-long-folder-name') x 3;
	make_path($deep);
	my $narrow_root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $narrow_terminal = Term::Fabulous::Terminal::Memory->new( width => 50, height => 26 );
	my $narrow          = Term::Fabulous->new( width => 50, height => 26, root => $narrow_root, terminal => $narrow_terminal );
	$narrow->step;
	my $dialog = $FileDialog->new( directory => $deep, list_rows => 4 )->open($narrow);
	$narrow->step;
	is $narrow->bounding_box($dialog)->{width}, 50, 'the dialog is as wide as the screen, not 70 columns';
	my ($line) = grep { /Folder: / } $narrow_terminal->lines;
	like $line, qr{Folder: \.\.\.[^/]*/a-rather-long-folder-name\s*\S\s*\z}, 'the folder line starts with ... and ends with the folder';
	$dialog->close;
};

subtest 'parameters' => sub {
	like dies { $FileDialog->new( mode         => 'move' ) },                              qr/mode/,            'an unknown mode dies';
	like dies { $FileDialog->new( directory    => "$top/todo.txt" ) },                     qr/is not a folder/, 'a directory that is no folder dies';
	like dies { $FileDialog->new( current_file => 'todo.txt' ) },                          qr/absolute path/,   'a relative current_file dies';
	like dies { $FileDialog->new( mode         => 'save', default_extension => '.txt' ) }, qr/without its dot/, 'an extension with its dot dies';
	is $FileDialog->new( directory => $top )->list->rows, [], 'the folder is read when the dialog opens, not before';
	like dies { $FileDialog->new( filters => [ [ 'Text' => '*.txt' ], [ 'Text' => '*.md' ] ] ) }, qr/two filters/, 'two filters with one label die';
};

done_testing;
