package Term::Fabulous::Widget::FileDialog;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Dialog;

our $VERSION = '0.05';

class Term::Fabulous::Widget::FileDialog
	:isa(Term::Fabulous::Widget::Dialog)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow);
	use Cwd qw(abs_path getcwd);
	use Encode qw(decode encode);
	use File::Basename qw(basename dirname);
	use File::Spec;
	use List::Util qw(any first min);
	use POSIX qw(strftime);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(boolean describe one_of positive_integer string);
	use Term::Fabulous::Text::Markup qw(escape_markup);
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Checkbox;
	use Term::Fabulous::Widget::Dropdown;
	use Term::Fabulous::Widget::FileDialog::FolderLine;
	use Term::Fabulous::Widget::Prompt;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Frame qw(framed);
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	use constant DEFAULT_WIDTH => 70;
	use constant CANCEL        => 'cancel';
	use constant FEWEST_ROWS   => 2;    # the entries the list keeps on a small screen

	# What each mode calls itself: its default title, the label and the
	# placeholder of the field, and the button (and answer) that takes
	# the choice.
	my %MODE = (
		open   => { title => 'Open a file',      field => 'File', placeholder => 'A file name or a path',   button => 'Open',   answer => 'open' },
		save   => { title => 'Save the file as', field => 'File', placeholder => 'A file name or a path',   button => 'Save',   answer => 'save' },
		folder => { title => 'Choose a folder',  field => 'Name', placeholder => 'A folder name or a path', button => 'Choose', answer => 'choose' },
	);

	my $generated_ids = 0;

	field $mode              :param = 'open';
	field $directory         :param = undef;    # bytes, as the file system has them
	field $current_file      :param = undef;    # bytes
	field $list_rows         :param = 10;
	field $show_hidden       :param = 0;
	field $default_extension :param = undef;
	field $confirm_overwrite :param = undef;

	field @_filters;    # [ { label, patterns => [ regex, ... ] } ], in order
	field $_filter;    # the index of the active filter, undef without filters
	field $_folder_line;
	field $_list;
	field $_field;
	field $_filter_choice;    # the Dropdown, undef with fewer than two filters
	field $_hidden_box;
	field $_replace_question;    # the open Replace question, a weak reference

	# A file dialog is a dialog with room at its sides and no gaps between
	# its parts (it has many), as wide as the program asks or as the
	# screen when that is narrower, with an id the id of its list derives
	# from. Its title and its two buttons come from its mode, and its
	# notice line always takes its row, so that a message does not move
	# the buttons.
	sub BUILDARGS ( $class, %params ) {
		my $width  = positive_integer( $class, width => delete $params{width} // DEFAULT_WIDTH );
		my $layout = $params{layout} // {};
		$params{id} //= 'file-dialog-' . ++$generated_ids;
		$params{layout} = {
			padding   => { left => 2, right => 2, top => 1, bottom => 1 },
			child_gap => 0,
			%$layout,
			sizing => { width => sizing_grow( 0, $width ), %{ $layout->{sizing} // {} } },
		};
		my @own = grep { exists $params{$_} } qw(buttons notice_line);
		die "$class: a file dialog has its own @own" if @own;
		$params{notice_line} = 'row';
		if ( my $words = $MODE{ $params{mode} // 'open' } ) {    # an unknown mode dies in ADJUST
			$params{title} //= $words->{title};
			$params{buttons} = [ { id => $words->{answer}, label => $words->{button}, primary => 1 }, { id => CANCEL, label => 'Cancel' } ];
		}
		return $class->SUPER::BUILDARGS(%params);
	}

	ADJUST :params ( :$filters = undef, :$name = undef ) {
		$mode = one_of( $self, mode => $mode, sort keys %MODE );
		if ( $mode eq 'folder' ) {
			my %meaningless = ( filters => $filters, default_extension => $default_extension, name => $name, confirm_overwrite => $confirm_overwrite );
			my @given       = grep { defined $meaningless{$_} } sort keys %meaningless;
			die ref($self) . ": a folder dialog takes no " . join( ', ', @given ) if @given;
		}
		$directory         = $self->_checked_directory( $directory // getcwd() );
		$current_file      = $self->_checked_current_file($current_file);
		$list_rows         = positive_integer( $self, list_rows => $list_rows );
		$show_hidden       = boolean( $self, show_hidden => $show_hidden );
		$default_extension = $self->_checked_extension($default_extension);
		$confirm_overwrite = boolean( $self, confirm_overwrite => $confirm_overwrite // 1 );
		@_filters          = $self->_parsed_filters( $filters // [] );
		$_filter           = @_filters ? 0 : undef;

		$self->_build( _decoded( $self->_checked_bytes( name => $name // '' ) ) );
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	# Paths and names come as the file system has them: bytes, not
	# characters.
	method _checked_bytes ( $name, $value ) {
		$value = string( $self, $name => $value );
		die ref($self) . ": $name must be bytes as the file system has them (encode it to UTF-8 first), got a character string" if $value =~ /[^\x00-\xff]/;
		return $value;
	}

	method _checked_directory ($path) {
		$path = $self->_checked_bytes( directory => $path );
		die ref($self) . ": directory '$path' is not a folder" unless -d $path;
		return _absolute($path);
	}

	method _checked_current_file ($path) {
		return undef unless defined $path;
		$path = $self->_checked_bytes( current_file => $path );
		die ref($self) . ": current_file must be an absolute path, got '$path'" unless File::Spec->file_name_is_absolute($path);
		return _canonical($path);
	}

	method _checked_extension ($extension) {
		return undef unless defined $extension;
		$extension = string( $self, default_extension => $extension );
		die ref($self) . ": default_extension must be an extension without its dot, like 'txt', got '$extension'" unless $extension =~ m{\A[^./\s][^/\s]*\z};
		return $extension;
	}

	# A filter is [ label, patterns ]: the patterns are globs separated by
	# white space, matched without case.
	method _parsed_filters ($filters) {
		die ref($self) . ": filters must be an array reference, got " . describe($filters) unless ref $filters eq 'ARRAY';
		my ( @parsed, %seen );
		foreach my $filter (@$filters) {
			die ref($self) . ": a filter must be [ label, patterns ], got " . describe($filter) unless ref $filter eq 'ARRAY' && @$filter == 2;
			my $label    = string( $self, 'the label of a filter' => $filter->[0] );
			my @patterns = split ' ', string( $self, "the patterns of the filter '$label'" => $filter->[1] );
			die ref($self) . ": the filter '$label' has no patterns" unless @patterns;
			die ref($self) . ": two filters are labelled '$label'" if $seen{$label}++;
			push @parsed, { label => $label, patterns => [ map { _glob_regex($_) } @patterns ] };
		}
		return @parsed;
	}

	sub _glob_regex ($glob) {
		my $regex = join '', map { $_ eq '*' ? '.*' : $_ eq '?' ? '.' : quotemeta } split /([*?])/, $glob;
		return qr/\A$regex\z/is;
	}

	# ---------------------------------------------------------------------
	# The parts
	# ---------------------------------------------------------------------

	method _build ($name) {
		my @size_column = $mode eq 'folder' ? () : ( { key => 'size', title => 'Size', width => 'fit', sortable => 0, align => 'right' } );
		$_folder_line = Term::Fabulous::Widget::FileDialog::FolderLine->new;
		$_list        = Term::Fabulous::Widget::Table->new(
			id           => $self->id . '/list',
			row_id       => 'entry',
			selection    => 'single',
			border       => 'none',
			column_lines => 'none',
			header_line  => 'Solid',
			columns      => [
				{ key => 'name', title => 'Name', width => 'grow', sortable => 0, cell => \&_name_cell },
				@size_column,
				{ key => 'modified', title => 'Modified', width => 'fit', sortable => 0 },
			],
			layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$_list->on( RowActivate => sub ( $self, $event ) { $self->_enter( $event->row_id );   return },                                  owner => $self );
		$_list->on( CursorMove  => sub ( $self, $event ) { $self->_pointed( $event->row_id ); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$_list->on(
			KeyPress => sub ( $self, $event ) { return ( $event->main_key_name // '' ) eq 'Backspace' && $self->_up ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE },
			owner    => $self
		);

		$_field = Term::Fabulous::Widget::TextField->new( value => $name, placeholder => $MODE{$mode}{placeholder}, layout => { sizing => { width => sizing_grow() } } );
		$_field->on( Submit => sub ( $self, $event ) { $self->_submitted( $event->value ); return }, owner => $self );
		my $field_row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 } );
		$field_row->add_child( Term::Fabulous::Widget::Text->new( text => $MODE{$mode}{field} ), $_field );

		my $options_row = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2 } );
		if ( @_filters > 1 ) {
			$_filter_choice = Term::Fabulous::Widget::Dropdown->new( options => [ map { $_->{label} } @_filters ], value => $_filters[0]{label} );
			$_filter_choice->on( Change => sub ( $self, $event ) { $self->filter( $event->value ); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
			$options_row->add_child($_filter_choice);
		}
		$_hidden_box = Term::Fabulous::Widget::Checkbox->new( label => 'Show hidden files', checked => $show_hidden );
		$_hidden_box->on( Change => sub ( $self, $event ) { $self->show_hidden( $event->value ); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$options_row->add_child($_hidden_box);

		# The list counts its header and the line below it as rows.
		$self->add_child( $_folder_line, framed( $_list, $list_rows + 2, min( $list_rows, FEWEST_ROWS ) + 2 ), $field_row, $options_row );
		return;
	}

	# A name too long for its column is cut from the left, so that it
	# does not push the size and the time out of the list.
	sub _name_cell ($cell) {
		return Term::Fabulous::Widget::FileDialog::FolderLine->new( label => '', path => $cell->{display} );
	}

	# The notice line above the buttons, empty while all is well: a text
	# and the path it is about, as given.
	method _say ( $text, $path = '', $after = '' ) {
		return $self->notice( join '', map { escape_markup($_) } $text, $path, $after );
	}

	# A file or folder that is not there, named as the user typed it.
	method _say_missing ( $kind, $target ) {
		return $self->_say( "There is no $kind ", $target->{shown}, $target->{here} ? ' in this folder.' : '.' );
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method directory () {
		return $directory;
	}

	method typed () {
		return $_field->value;
	}

	method list () {
		return $_list;
	}

	method filter (@new) {
		return defined $_filter ? $_filters[$_filter]{label} : undef unless @new;
		my $label = $new[0];
		my $index = first { $_filters[$_]{label} eq ( $label // '' ) } 0 .. $#_filters;
		die ref($self) . ": the dialog has no filter labelled " . describe($label) unless defined $index;
		$_filter = $index;
		$_filter_choice->value($label) if defined $_filter_choice && ( $_filter_choice->value // '' ) ne $label;
		$self->_list_directory if $self->is_open;
		return $label;
	}

	method show_hidden (@new) {
		return $show_hidden unless @new;
		$show_hidden = boolean( $self, show_hidden => $new[0] );
		$_hidden_box->checked($show_hidden) if $_hidden_box->checked != $show_hidden;
		$self->_list_directory if $self->is_open;
		return $show_hidden;
	}

	# ---------------------------------------------------------------------
	# The folder
	# ---------------------------------------------------------------------

	method _list_directory () {
		$_folder_line->path( _decoded($directory) );
		my @rows = $directory eq File::Spec->rootdir ? () : ( { name => '../', entry => '..', kind => 'up', size => '', modified => '' } );
		if ( opendir my $handle, $directory ) {
			push @rows, $self->_rows_of( grep { $_ ne '.' && $_ ne '..' } readdir $handle );
			closedir $handle;
			$self->_say('');
		}
		else {
			$self->_say("Cannot read the folder: $!.");
		}
		$_list->rows( \@rows );
		return;
	}

	# The rows of the folder's entries: the folders, then the files the
	# filter lets through, each sorted by the name shown.
	method _rows_of (@entries) {
		my ( @folders, @files );
		foreach my $entry ( grep { $show_hidden || !/\A\./ } @entries ) {
			my $path = File::Spec->catfile( $directory, $entry );
			my $name = _decoded($entry);
			if ( -d $path ) {
				push @folders, { name => "$name/", entry => $entry, kind => 'folder', size => '', modified => _when($path) };
				next;
			}
			next if $mode eq 'folder' || !$self->_passes_filter($name);
			push @files, { name => $name, entry => $entry, kind => 'file', size => _size($path), modified => _when($path) };
		}
		return map {
			sort { fc $a->{name} cmp fc $b->{name} or $a->{entry} cmp $b->{entry} }
				@$_
		} \@folders, \@files;
	}

	method _passes_filter ($name) {
		return 1 unless defined $_filter;
		return any { $name =~ $_ } @{ $_filters[$_filter]{patterns} };
	}

	sub _size ($path) {
		my $bytes = -s $path // 0;
		return $bytes < 1024 ? "$bytes B" : $bytes < 1024 * 1024 ? sprintf( '%.1f KiB', $bytes / 1024 ) : sprintf( '%.1f MiB', $bytes / 1024 / 1024 );
	}

	sub _when ($path) {
		my $time = ( stat $path )[9] // return '';
		return strftime( '%Y-%m-%d %H:%M', localtime $time );
	}

	# The file system's names are bytes; the dialog shows and matches them
	# as UTF-8 text, with a byte that is no UTF-8 shown as \xHH.
	sub _decoded ($bytes) {
		return decode( 'UTF-8', $bytes, Encode::FB_PERLQQ | Encode::LEAVE_SRC );
	}

	sub _encoded ($text) {
		return encode( 'UTF-8', $text );
	}

	# An absolute path without symbolic links, or just made absolute when
	# they cannot be resolved.
	sub _absolute ($path) {
		return abs_path($path) // File::Spec->rel2abs($path);
	}

	# The same for a file that may not exist yet: its folder resolved.
	sub _canonical ($path) {
		return _absolute($path) if -d $path;
		return File::Spec->catfile( _absolute( dirname($path) ), basename($path) );
	}

	# Another folder: the field empties, except in save mode, where it
	# keeps the name to save under.
	method _go ($path) {
		$directory = _absolute($path);
		$_field->value('') unless $mode eq 'save';
		$self->_list_directory;
		return 1;
	}

	method _up () {
		return 0 if $directory eq File::Spec->rootdir;
		return $self->_go( dirname($directory) );
	}

	# Enter or a double click on an entry: a folder opens, a file is
	# chosen (and shown in the field).
	method _enter ($entry) {
		return unless defined $entry;
		my $row = $_list->row($entry);
		return $self->_up if $row->{kind} eq 'up';
		return $self->_go( File::Spec->catdir( $directory, $entry ) ) if $row->{kind} eq 'folder';
		$_field->value( $row->{name} );
		$self->choose( $row->{name} );
		return;
	}

	# In open mode the cursor on a file puts its name into the field; in
	# folder mode the cursor on a folder does, and on ../ empties it. In
	# save mode the field keeps the name typed.
	method _pointed ($entry) {
		return unless defined $entry;
		my $row = $_list->row($entry);
		if ( $mode eq 'folder' ) {
			$_field->value( $row->{kind} eq 'folder' ? $row->{name} =~ s{/\z}{}r : '' );
			return;
		}
		$_field->value( $row->{name} ) if $mode eq 'open' && $row->{kind} eq 'file';
		return;
	}

	# ---------------------------------------------------------------------
	# Choosing
	# ---------------------------------------------------------------------

	# What a text in the field names: the entry the list shows under this
	# name, or else the text as a path (in UTF-8 for the file system):
	# relative to the folder shown, absolute, or starting with ~ for the
	# home folder. The target keeps the text, to name it in messages, and
	# whether it is relative to the folder shown. Undef for no text.
	method _target ($typed) {
		my $shown = $typed =~ s/\A\s+|\s+\z//gr;
		return undef unless length $shown;
		my $row = first { $_->{kind} ne 'up' && ( $_->{name} =~ s{/\z}{}r ) eq $shown } @{ $_list->rows };
		return { path => File::Spec->catfile( $directory, $row->{entry} ), shown => $shown, here => 1 } if defined $row;
		my $path = _encoded($shown) =~ s{\A~(?=/|\z)}{$ENV{HOME} // '~'}er;
		return { path => $path, shown => $shown, here => 0 } if File::Spec->file_name_is_absolute($path);
		return { path => File::Spec->catfile( $directory, $path ), shown => $shown, here => 1 };
	}

	# Enter in the field: in folder mode a folder typed opens, an empty
	# field chooses the folder shown; otherwise as the button.
	method _submitted ($typed) {
		return $self->choose($typed) unless $mode eq 'folder';
		my $target = $self->_target($typed) // return $self->choose('');
		return $self->_say_missing( folder => $target ) unless -d $target->{path};
		$self->_go( $target->{path} );
		return;
	}

	method choose ($typed) {
		die ref($self) . ": choose needs an open dialog" unless $self->is_open;
		my $target = $self->_target($typed);
		return $self->_choose_folder($target) if $mode eq 'folder';
		return $self->_say( $mode eq 'open' ? 'Choose a file, or type its name.' : 'Type a file name.' ) unless defined $target;
		if ( -d $target->{path} ) {    # a folder typed is used up: it opens
			$_field->value('');
			$self->_go( $target->{path} );
			return $self;
		}
		return $mode eq 'open' ? $self->_choose_file_to_open($target) : $self->_choose_file_to_save($target);
	}

	method _choose_folder ($target) {
		return $self->_answer( _absolute($directory) ) unless defined $target;
		return $self->_say_missing( folder => $target ) unless -d $target->{path};
		return $self->_answer( _absolute( $target->{path} ) );
	}

	method _choose_file_to_open ($target) {
		return $self->_say_missing( file => $target ) unless -f $target->{path};
		return $self->_answer( _canonical( $target->{path} ) );
	}

	method _choose_file_to_save ($target) {
		my ( $path, $shown ) = @$target{qw(path shown)};
		( $path, $shown ) = ( "$path.$default_extension", "$shown.$default_extension" ) if defined $default_extension && basename($path) !~ /\./;
		return $self->_say_missing( folder => _folder_target( $target, $path, $shown ) ) unless -d dirname($path);
		return $self->_say( '', $shown, ' is a folder.' ) if -d $path;    # a folder only once the default extension is added
		$path = _canonical($path);
		return $self->_ask_to_replace($path) if $confirm_overwrite && -e $path && $path ne ( $current_file // '' );
		return $self->_answer($path);
	}

	# The folder of a file to save that is not there, named by the folder
	# part of the text typed.
	sub _folder_target ( $target, $path, $shown ) {
		my ($folder) = $shown =~ m{\A(.*)/};
		return { shown => _decoded( dirname($path) ), here => 0 } unless defined $folder;
		return { here => $target->{here}, shown => length $folder ? $folder : '/' };
	}

	# A question above the dialog, starting on Cancel: Replace answers
	# with the path, Cancel or Escape leave the dialog open.
	method _ask_to_replace ($path) {
		my $question = Term::Fabulous::Widget::Prompt->confirm(
			$self->ui,
			title   => 'Replace the file?',
			message => '[bold]' . ( _decoded( basename($path) ) =~ s/\[/\\[/gr ) . '[/] already exists. Replace it?',
			ok      => 'Replace',
			focus   => CANCEL,
			z_index => $self->z_index + 1,
		);
		$question->on(
			Answer => sub ( $self, $event ) {
				$self->_answer($path) if $event->button eq 'ok' && $self->is_open;
				return;
			},
			owner => $self
		);
		weaken( $_replace_question = $question );
		return $self;
	}

	method _close_question () {
		$_replace_question->close if defined $_replace_question && $_replace_question->is_open;
		return;
	}

	# ---------------------------------------------------------------------
	# Opening and answering
	# ---------------------------------------------------------------------

	# The folder is read each time the dialog opens. Save mode starts in
	# the field.
	method open :override ($ui) {
		return $self if $self->is_open;
		$self->_list_directory;
		$self->SUPER::open($ui);
		$self->_select_name($ui) if $mode eq 'save';
		return $self;
	}

	# The field focused with the name selected up to its extension, so
	# typing replaces the name and keeps the extension.
	method _select_name ($ui) {
		my $stem = $_field->value =~ s/(?<=.)\.[^.]*\z//r;
		$ui->interaction->set_focused_widget($_field);
		$_field->editor->set_selection( 0, 0, 0, length $stem );
		return;
	}

	# A choice answers with the button of the mode and the path.
	method _answer ($path) {
		return $self->answer( $MODE{$mode}{answer}, path => $path );
	}

	# The button of the mode chooses what the field names; Cancel answers.
	method press_button :override ($id) {
		return $self->choose( $self->typed ) if $id eq $MODE{$mode}{answer};
		return $self->SUPER::press_button($id);
	}

	# Whatever closes the dialog (an answer, Escape, close from the
	# program) closes the question above it first.
	method answer :override ( $id, %values ) {
		$self->_close_question;
		return $self->SUPER::answer( $id, %values );
	}

	method close :override () {
		$self->_close_question;
		return $self->SUPER::close;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::FileDialog - A dialog that asks for a file to
open or save, or for a folder

=head1 SYNOPSIS

	use Term::Fabulous::Widget::FileDialog;

	# A file to open, from the theme files or from all files:
	my $dialog = Term::Fabulous::Widget::FileDialog->new(
		mode      => 'open',
		directory => "$ENV{HOME}/themes",
		filters   => [ [ 'Theme files' => '*.kdl' ], [ 'All files' => '*' ] ],
	);
	$dialog->on( Answer => sub ($event) {
		load_theme( $event->value('path') ) if $event->button eq 'open';    # bytes, ready for open
		return;
	} );
	$dialog->open($ui);

	# Where to save: a name without a dot gets .kdl, and a file other
	# than the one being saved is replaced only after a question.
	Term::Fabulous::Widget::FileDialog->new(
		mode              => 'save',
		name              => 'ocean.kdl',
		current_file      => $document->path,    # absolute, or undef for an untitled one
		default_extension => 'kdl',
	)->on( Answer => sub ($event) {
		$document->save_as( $event->value('path') ) if $event->button eq 'save';
		return;
	} )->open($ui);

	# A folder:
	Term::Fabulous::Widget::FileDialog->new( mode => 'folder' )->on( Answer => sub ($event) {
		chdir $event->value('path') if $event->button eq 'choose';
		return;
	} )->open($ui);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-file-dialog.svg" alt="An Open a file dialog over a dimmed notes program: the folder line ends in Documents/Projects/analytical-engine/notes, the list shows two folders and four notes with their sizes and modification times, the cursor is on reading-list.txt, which is also in the File field, and below it are the Notes filter, the Show hidden files checkbox and the Open and Cancel buttons"></p>

=end html

The program is F<examples/widgets/file-dialog.pl>. The picture shows
the dialog to open a note after the cursor moved down to
F<reading-list.txt>: the cursor put the name into the field, and the
filter C<Notes> hides the files that are no notes.

=head1 DESCRIPTION

A file dialog is a L<Term::Fabulous::Widget::Dialog> that lists the
folders and files of a folder and lets the user walk through the
folders, pick an entry or type a name. Like a
L<Term::Fabulous::Widget::Prompt>, it reports the answer with one
event, L<Answer|Term::Fabulous::Event::Answer>, after it closed.

From the top, it shows its title, the folder it lists, the list, a
field for a name or a path (C<File>, or C<Name> in folder mode), a row
with the filter dropdown and the C<Show hidden files> checkbox, the
dialog's notice line, which says what is wrong while something is
(always at least one row, so a one-row message does not change the
dialog's height:
C<< notice_line => 'row' >>, see
L<Term::Fabulous::Widget::Dialog/notice_line>), and the buttons. The
folder line shows as much of the end of the path as fits the width the
dialog gets, after C<...> when its start had to go. The notice names a
path as typed, and wraps when it is too long for one row.

On a screen too low for the whole dialog, the list gives up rows
first, down to two entries; on a narrower screen than C<width>, the
dialog is as wide as the screen.

=head2 Modes

=over

=item C<open>

The user chooses a file that exists. The button is C<Open>.

=item C<save>

The user chooses a name for a file, in a folder that exists. The button
is C<Save>. A name without a dot gets the C<default_extension>, when
there is one. The dialog opens with the focus in the field and the
name selected up to its extension, so typing replaces the name and
keeps the extension. See L</Saving over a file>.

=item C<folder>

The user chooses a folder. The list shows folders only and has no
C<Size> column, the field is labelled C<Name>, and the button is
C<Choose>.

=back

=head2 The list

The list has three columns: the name (folders end in C</>), the size of
a file (not in folder mode) and the time it was last modified. A name
too long for its column is cut from the left, after C<...>, so the
size and the time stay in view. The parent folder C<../> comes first,
then the folders, then the files, each sorted by name without regard
to case. Names that start with a dot are shown only while C<Show
hidden files> is checked.

The list has its frame in the accent color while it has the keyboard
focus, and it has the focus when the dialog opens in open and folder
mode. C<Enter> or a double click on an entry opens a folder (C<../> is
the parent folder) or chooses a file; C<Backspace> goes to the parent
folder.

What the list does to the field depends on the mode. In open mode, the
cursor on a file puts its name into the field. In folder mode, the
cursor on a folder puts its name into the field, and the cursor on
C<../> empties it. In both, going to another folder empties the field.
In save mode, the field keeps the name typed: the cursor and going to
another folder leave it alone, and only C<Enter> or a double click on
a file puts that file's name into it (and saves to it, see
L</Saving over a file>).

=head2 Typing a name

C<Enter> in the field takes the name or path in it: relative to the
folder shown, absolute, or starting with C<~> for the home folder. A
folder opens, and the field empties. In open and save mode, anything
else is chosen as the button does.

The messages name what was typed: a file that is not there is
C<There is no file notes.txt in this folder.> when opening (for an
absolute path or one with C<~>, the path and a full stop), and a file
in a folder that is not there is C<There is no folder drafts in this
folder.> when saving C<drafts/notes.txt>. A name that names a folder
only once the C<default_extension> is added (C<notes> when there is a
folder C<notes.kdl>) is C<notes.kdl is a folder.> when saving.

In folder mode, C<Enter> in the field opens the folder typed, and with
an empty field it chooses the folder shown. C<Choose> answers the
folder in the field (relative to the folder shown) when the field has
text, and otherwise the folder shown. A folder that is not there is
C<There is no folder ... in this folder.>

C<Tab> and C<Shift+Tab> move between the parts. C<Escape> or C<Cancel>
closes the dialog without a choice.

=head2 Filters and hidden files

A filter has a label and one or more patterns: globs separated by
spaces, where C<*> stands for any text and C<?> for one character, so
C<*.txt *.md> lets text and Markdown files through. Patterns are
matched against the whole name without regard to case, and folders
always show. With two or more filters, a
L<Term::Fabulous::Widget::Dropdown> in front of the checkbox picks the
active one, the first at the start. With one filter, it applies and no
dropdown shows. Without filters, the list shows all files.

=head2 File names

The file system's names are bytes. The dialog shows them decoded from
UTF-8, with a byte that is no UTF-8 shown as C<\xHH>, so every name
shows and can be chosen; filters match the decoded names. A text typed
into the field is encoded to UTF-8 for the file system, except a name
that the list shows (one with C<\xHH> too), which is the entry as the
file system has it.

The C<path> of an answer is a byte string, exactly what the file system
uses, ready for C<open>; decode it to show it. The parameters
C<directory>, C<name> and C<current_file>, and the L</directory> the
dialog shows, are byte strings too. The field's text (L</typed>,
L</choose>) is characters.

=head2 Saving over a file

In save mode, a file that exists is replaced only after a question,
unless it is the C<current_file>, the file of the document being
saved. The question is a L<Term::Fabulous::Widget::Prompt> (C<Replace
the file?>, with the buttons C<Replace> and C<Cancel>) that opens above
the file dialog, which is dimmed behind it, with the focus on
C<Cancel>. C<Replace> closes both and the file dialog answers.
C<Cancel> or C<Escape> on the question puts the focus back into the
file dialog, which stays open. Closing or answering the file dialog
from the program (L</close>, C<answer>) closes the question too.
An untitled document has no C<current_file>, so saving it over any
existing file asks.
C<< confirm_overwrite => 0 >> never asks.

=head2 Answers

When the user chose a file or a folder, the dialog closes, the focus
goes back to the widget that had it before, and the dialog fires
C<Answer>. The button of the answer is the mode's: C<open>, C<save> or
C<choose>, and its values are C<< { path => $path } >>, the absolute
path of the file or folder (with no symbolic links in its folders), as
bytes (see L</File names>). The dialog checks only that a file to open
is there, and that the folder of a file to save is there and the file
is not a folder: reading and writing are up to the program.

The C<Cancel> button answers C<cancel>, with C<dismissed> false.
C<Escape>, or L</close> from the program, answers C<cancel> as well,
with C<dismissed> true. A cancelled dialog's values are C<{}>: a file
dialog has no values of its own (see
L<Term::Fabulous::Widget::Dialog/Answers>). A file dialog answers once
each time it is opened. Its buttons are the dialog's: the mode's
(C<open>, C<save> or C<choose>, primary) chooses what the field names
(see L</choose>), and C<cancel> answers.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $dialog = Term::Fabulous::Widget::FileDialog->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Dialog/new>
(C<id>, C<layout>, C<backdrop_color>, C<z_index>, ...) and the ones
below. All are optional, and unknown parameters die. A file dialog is
laid out like a dialog, with two columns of padding at the sides
instead of one.

=over

=item C<id>

The dialog's id, a string; the list inside it gets the id C<"$id/list">.
Default: a new id, C<file-dialog-1>, C<file-dialog-2> and so on.

=item C<mode>

C<open>, C<save> or C<folder>. Default: C<open>. Anything else dies.

=item C<directory>

The folder the dialog starts in, a byte string (see L</File names>).
Default: the current working directory. A path that is no folder, and
a string with characters above 255, die.

=item C<name>

The name the field starts with, such as the name a document had, a
byte string; the field shows it decoded. Default: C<''>.

=item C<current_file>

The absolute path of the file of the document being saved, a byte
string, or C<undef> for a document that has no file yet. Saving to
this file asks no question. Default: C<undef>. A relative path dies.

=item C<title>

The dialog's title (L<Term::Fabulous::Widget::Dialog/title>), drawn in
bold on the first row. Default: C<Open a file>, C<Save the file as> or
C<Choose a folder>, after the mode. The C<buttons> and C<notice_line>
of a dialog are the file dialog's own; giving them dies.

=item C<filters>

An array reference of filters, each C<[ $label, $patterns ]>: the label
is the text the dropdown shows, and the patterns are globs separated by
spaces (see L</Filters and hidden files>). Default: C<[]>, all files.
A filter without patterns and two filters with the same label die.

=item C<default_extension>

The extension a name without a dot gets when saving, without its dot:
C<< default_extension => 'kdl' >>. Default: C<undef>, none. An empty
extension, one that starts with a dot, and one with a slash or white
space die.

=item C<confirm_overwrite>

A boolean: whether saving over an existing file other than the
C<current_file> asks first. Default: 1.

=item C<show_hidden>

A boolean: whether the C<Show hidden files> checkbox starts checked.
Default: 0.

=item C<list_rows>

The number of entries the list shows, a positive integer. Default: 10.
On a screen too low for the dialog, the list shows fewer, down to two
(or C<list_rows>, when that is less).

=item C<width>

The width of the dialog in columns, a positive integer. Default: 70. On
a screen narrower than that, the dialog is as wide as the screen. A
width in the C<sizing> of C<layout> wins over it.

=back

In folder mode, C<filters>, C<default_extension>, C<name> and
C<confirm_overwrite> mean nothing, and giving any of them dies.

=head1 METHODS

A file dialog has all methods of L<Term::Fabulous::Widget::Dialog>
(C<open>, C<close>, C<is_open>, ...) plus these. Opening it reads the
folder; the list is empty until then.

=head2 choose

	$dialog->choose('notes/todo.txt');

Does what the dialog's button does with this text (a character string)
in the field: a folder in open or save mode opens it, a file is chosen
(and may ask before it is replaced), and in folder mode the folder is
chosen (the folder shown for an empty text). What is wrong shows above
the buttons and keeps the dialog open. Dies when the dialog is not
open. Returns the dialog.

=head2 typed

	my $text = $dialog->typed;

The text in the field, a character string.

=head2 directory

	my $folder = $dialog->directory;

The absolute path of the folder the dialog shows, a byte string.

=head2 list

	my $table = $dialog->list;

The L<Term::Fabulous::Widget::Table> of the folder's entries. Its rows
have the keys C<name> (the name shown, decoded, with a C</> after a
folder), C<entry> (the name as the file system has it, bytes; C<..>
for C<../>), C<kind> (C<up>, C<folder> or C<file>), C<size> and
C<modified>, and C<entry> is the row id.

=head2 filter

	my $label = $dialog->filter;
	$dialog->filter('All files');

Accessor for the active filter, by its label; C<undef> for a dialog
without filters. Writing makes another filter active, shows it in the
dropdown and lists the folder again. A label no filter has dies.

=head2 show_hidden

	$dialog->show_hidden(1);

Accessor for whether names that start with a dot are shown. Writing
checks or unchecks the checkbox and lists the folder again.

=head2 close

	$dialog->close;

Closes the dialog without a choice, as C<Escape> does, and the Replace
question above it when that is open: after the dialog's C<Close>, it
answers C<cancel> with C<dismissed> true. Does nothing while the
dialog is closed.

=head1 EVENTS

A file dialog fires the events of every dialog
(L<Term::Fabulous::Widget::Dialog/EVENTS>): C<Close>, then C<Answer>
(L<Term::Fabulous::Event::Answer>, see L</Answers>), once per opening.
The C<Answer> says that the user chose a file or a folder, or
cancelled; it is fired on the dialog after it closed and gave the focus
back.

The C<Change> events of the filter dropdown and the checkbox bubble
through the dialog as usual.

=head1 KDL PROPERTIES

A file dialog is built in Perl only: its paths are byte strings and
its filters structured, which a layout file cannot pass to C<new>.

=head1 SEE ALSO

L<Term::Fabulous::Event::Answer>, L<Term::Fabulous::Widget::Dialog>,
L<Term::Fabulous::Widget::Prompt>, L<Term::Fabulous::Widget::Table>,
L<Term::Fabulous::Manual::Feedback/FILE DIALOGS>,
L<Term::Fabulous::Cookbook::Forms/Open and save a file (FileDialog)>.

=cut
