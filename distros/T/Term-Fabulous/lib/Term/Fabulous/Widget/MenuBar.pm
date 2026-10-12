package Term::Fabulous::Widget::MenuBar;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Input;

our $VERSION = '0.02';

class Term::Fabulous::Widget::MenuBar
	:isa(Term::Fabulous::Widget::Input)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow);
	use List::Util qw(first sum0);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe non_negative_integer string);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_MOD_MOTION TB_UNDERLINE);
	use Term::Fabulous::Unicode qw(string_columns);
	use Term::Fabulous::Widget::Menu;

	use constant GAP => 2;    # columns between two titles

	field $commands :param = undef;
	field $caption  :param = '';

	field @_menus;    # [ { title, key, menu } ], in order
	field $_open;    # the index of the open menu, or undef
	field $_focus_before;    # the widget that had the focus when the bar opened

	ADJUST :params ( :$menus ) {
		die ref($self) . ": commands must be a Term::Fabulous::Commands, got " . describe($commands) if defined $commands && !( blessed $commands && $commands->isa('Term::Fabulous::Commands') );
		$caption = string( $self, caption => $caption );
		@_menus  = $self->_parsed_menus($menus);
		$self->can_focus(0);

		# A choice bubbles from the open menu through the bar, which closes
		# there, and goes on to the bar's ancestors. A listener on the menu
		# that stops it leaves the closing to menu_chosen.
		weaken( my $weak_self = $self );
		$self->on( Choose => sub ($event) { $weak_self->menu_chosen( $event->target ); return Clay::UI::Enum::Result->CONTINUE } );
		$self->on(
			MouseMove => sub ($event) {
				$weak_self->_pointer_over($event) if refaddr( $event->target ) == refaddr($weak_self);
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
	}

	method theme_family :common () {
		return 'menu_bar';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			caption_color              => [ 'caption',              'normal', 'cell_color' ],
			highlight_text_color       => [ 'highlight.text',       'normal', 'cell_color' ],
			highlight_background_color => [ 'highlight.background', 'normal', 'cell_color' ],
		);
	}

	# The menus: a title, its mnemonic letter (the first letter of the
	# title unless given; it must be in the title), and the items of its
	# menu. Two menus with one letter, and a letter whose Alt key runs a
	# command, die.
	method _parsed_menus ($menus) {
		die ref($self) . ": menus must be a non-empty array reference, got " . describe($menus) unless ref $menus eq 'ARRAY' && @$menus;
		my ( @parsed, %title_of_key );
		foreach my $definition (@$menus) {
			die ref($self) . ": a menu must be a hash reference with a title and items, got " . describe($definition) unless ref $definition eq 'HASH';
			my %rest  = %$definition;
			my $title = string( $self, 'the title of a menu' => delete $rest{title} );
			die ref($self) . ": the title of a menu must not be empty" unless length $title;
			my $key = lc string( $self, "the key of the menu '$title'" => delete $rest{key} // substr( $title, 0, 1 ) );
			die ref($self) . ": the key of the menu '$title' must be one letter or digit of its title, got '$key'" unless $key =~ /\A[[:alnum:]]\z/ && index( lc $title, $key ) >= 0;
			die ref($self) . ": the menus '$title_of_key{$key}' and '$title' have the same key '$key'; give one of them another key" if exists $title_of_key{$key};
			$self->_check_free_key( $title, $key ) if defined $commands;
			my $items = delete $rest{items};
			die ref($self) . ": the menu '$title' has unknown keys: " . join( ', ', sort keys %rest ) if %rest;
			my $menu = Term::Fabulous::Widget::Menu->new( items => $items // [], commands => $commands );
			$menu->can_focus(0);
			$title_of_key{$key} = $title;
			push @parsed, { title => $title, key => $key, menu => $menu };
		}
		return @parsed;
	}

	# Alt and the letter open the menu, with Shift or without, so neither
	# may run a command.
	method _check_free_key ( $title, $key ) {
		foreach my $name ( 'Alt+' . lc $key, 'Alt+' . uc $key ) {
			my $command = $commands->command_for_key($name) // next;
			die ref($self) . ": the key $name of the menu '$title' runs the command '" . $command->id . "'";
		}
		return;
	}

	method caption (@new) {
		return $caption unless @new;
		$caption = string( $self, caption => $new[0] );
		$self->mark_changed;
		return $caption;
	}

	method caption_color              (@new) { return @new ? $self->set_look( caption_color              => $new[0] ) : $self->look_value('caption_color') }
	method highlight_text_color       (@new) { return @new ? $self->set_look( highlight_text_color       => $new[0] ) : $self->look_value('highlight_text_color') }
	method highlight_background_color (@new) { return @new ? $self->set_look( highlight_background_color => $new[0] ) : $self->look_value('highlight_background_color') }

	method titles () {
		return map { $_->{title} } @_menus;
	}

	method menu ($index) {
		$index = $self->_checked_index($index);
		return $_menus[$index]{menu};
	}

	method _checked_index ($index) {
		$index = non_negative_integer( $self, index => $index );
		die ref($self) . ": there is no menu $index (the bar has " . scalar(@_menus) . ")" if $index > $#_menus;
		return $index;
	}

	# The menu whose mnemonic is a letter (Alt+F opens File), or undef.
	method menu_for_key ($letter) {
		return undef unless defined $letter && !ref $letter;
		return first { $_menus[$_]{key} eq lc $letter } 0 .. $#_menus;
	}

	# A press on the bar opens a menu without taking the focus from the
	# widget the user was in (see Term::Fabulous, KEYBOARD AND FOCUS).
	method keeps_focus_on_click () {
		return 1;
	}

	# ---------------------------------------------------------------------
	# Opening and closing
	# ---------------------------------------------------------------------

	method open_menu () {
		return $_open;
	}

	method is_open () {
		return defined $_open ? 1 : 0;
	}

	# An input's value: the index of the open menu.
	method value () {
		return $_open;
	}

	# The column a menu's title starts at, its padding included.
	method _title_column ($index) {
		return sum0( map { string_columns( $_menus[$_]{title} ) + GAP } 0 .. $index - 1 );
	}

	# The menu whose title covers a column, or undef.
	method _menu_at ($column) {
		return first {
			my $start = $self->_title_column($_);
			$column >= $start && $column < $start + string_columns( $_menus[$_]{title} ) + GAP;
		} 0 .. $#_menus;
	}

	# Opens a menu below its title, or switches to it while another one is
	# open. The bar takes the focus and hands the keys to the menu.
	method open ($index) {
		$index = $self->_checked_index($index);
		my $ui = $self->ui // die ref($self) . ": a menu bar opens its menus only while it is in a Term::Fabulous UI";
		die ref($self) . ": a disabled menu bar cannot open its menus" unless $self->is_enabled;
		return $self if defined $_open && $_open == $index;
		if ( !defined $_open ) {
			my $focused = $self->_focus_to_give_back($ui);
			$_focus_before = defined $focused && !$self->contains($focused) ? $focused : undef;
			weaken $_focus_before if defined $_focus_before;
		}
		my $previous = defined $_open ? $_menus[$_open]{menu} : undef;
		$_open = $index;
		$self->remove_child($previous) if defined $previous;
		my $menu = $_menus[$index]{menu};
		$menu->show_below( $self, $self->_title_column($index) );
		$self->add_child($menu);
		$self->can_focus(1);
		$ui->interaction->set_focused_widget($self) unless $self->is_focused;
		$self->mark_changed;
		return $self;
	}

	# The widget the bar gives the focus back to when it closes. A click
	# on a title keeps the focus where it is, which may be a context menu:
	# that one closes first and gives the focus back to its own widget.
	method _focus_to_give_back ($ui) {
		my $focused = $ui->interaction->get_focused_widget;
		return $focused unless blessed $focused && $focused->isa('Term::Fabulous::Widget::Menu') && $focused->is_open;
		$focused->close;
		return $ui->interaction->get_focused_widget;
	}

	# Closes the open menu. The focus goes back to the widget that had it
	# when the bar opened, unless it went elsewhere already.
	method close () {
		return $self unless defined $_open;
		my $menu      = $_menus[$_open]{menu};
		my $ui        = $self->ui;
		my $give_back = $_focus_before;
		my $had_focus = $self->is_focused;
		( $_open, $_focus_before ) = ( undef, undef );
		$self->remove_child($menu);
		if ( defined $ui && $had_focus ) {
			$give_back = undef if defined $give_back && !$ui->interaction->can_take_focus($give_back);
			$ui->interaction->set_focused_widget($give_back);
		}
		$self->can_focus(0);
		$self->mark_changed;
		return $self;
	}

	method focus_changed :override ($is_focused) {
		$self->close if !$is_focused && defined $_open;
		return;
	}

	# While a menu is open, Tab and Shift+Tab switch menus.
	method captures_tab () {
		return $self->is_open;
	}

	# A menu of the bar chose an item: the bar closes before the command
	# runs.
	method menu_chosen ($menu) {
		$self->close if defined $_open && refaddr( $_menus[$_open]{menu} ) == refaddr($menu);
		return;
	}

	# ---------------------------------------------------------------------
	# Keys and the mouse
	# ---------------------------------------------------------------------

	# F10 opens the first menu, Alt and a menu's letter that menu; returns
	# whether the key opened one.
	method handle_shortcut ($event) {
		return 0 unless $self->is_enabled;
		my $name = $event->key_name // return 0;
		if ( $name eq 'F10' ) {
			$self->open(0);
			return 1;
		}
		my ($letter) = $name =~ /\AAlt\+([[:alnum:]])\z/ or return 0;
		my $index = $self->menu_for_key($letter) // return 0;
		$self->open($index);
		return 1;
	}

	# Opens menus for the keys that reach a widget, usually the root.
	method listen ($widget) {
		die ref($self) . ": listen needs a widget that fires events, got " . describe($widget) unless blessed $widget && $widget->can('on');
		weaken( my $weak_self = $self );
		$widget->on( KeyPress => sub ($event) { return $weak_self && $weak_self->handle_shortcut($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
		return $self;
	}

	# While a menu is open, the bar has the focus and gets every key: the
	# menu uses its own, the bar switches and closes menus, keys with Ctrl
	# or Alt close the bar and go on, and the rest are kept.
	method handle_key ($event) {
		return 0 unless defined $_open;
		return 1 if $_menus[$_open]{menu}->handle_key($event);
		my $name = $event->key_name // '';
		my %step = ( Left => -1, BackTab => -1, Right => 1, Tab => 1 );
		if ( exists $step{$name} ) {
			$self->open( ( $_open + $step{$name} ) % @_menus );
			return 1;
		}
		if ( $name eq 'Escape' || $name eq 'F10' ) {
			$self->close;
			return 1;
		}
		if ( my ($letter) = $name =~ /\AAlt\+([[:alnum:]])\z/ ) {
			my $index = $self->menu_for_key($letter);
			if ( defined $index ) {
				$self->open($index);
				return 1;
			}
		}
		return 1 unless $name =~ /\A(?:Ctrl|Alt)\+/;
		$self->close;
		return 0;
	}

	# A press on a title opens its menu, or closes it when it is open.
	method handle_mouse ($event) {
		return 0 unless refaddr( $event->target ) == refaddr($self);
		return 0 unless $event->key == TB_KEY_MOUSE_LEFT && !( $event->modifiers & TB_MOD_MOTION );
		my ($column) = $self->cell_at($event);
		my $index = defined $column ? $self->_menu_at($column) : undef;
		return 1 unless defined $index;
		defined $_open && $_open == $index ? $self->close : $self->open($index);
		return 1;
	}

	# While a menu is open, the pointer over another title opens that one.
	method _pointer_over ($event) {
		return unless defined $_open;
		my ($column) = $self->cell_at($event);
		my $index = defined $column ? $self->_menu_at($column) : undef;
		$self->open($index) if defined $index && $index != $_open;
		return;
	}

	# A click is handled by handle_mouse, on the press.
	method activate :override () {
		return;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method natural_size () {
		return ( sizing_grow( $self->_title_column( scalar @_menus ) ), 1 );
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $_open // -1, $caption );
	}

	# Each title with a space on each side, the open one highlighted, its
	# letter underlined; the caption at the right end when it fits.
	method paint () {
		my $text      = $self->color_attr( $self->text_color );
		my @highlight = ( $self->color_attr( $self->highlight_text_color ), $self->color_attr( $self->highlight_background_color ) );
		foreach my $index ( 0 .. $#_menus ) {
			my ( $title, $key ) = @{ $_menus[$index] }{qw(title key)};
			my ( $fg,    $bg )  = defined $_open && $_open == $index ? @highlight : ( $text, undef );
			my $start = $self->_title_column($index);
			$self->fill_attrs( $start, 0, string_columns($title) + GAP, ' ', $fg, $bg ) if defined $bg;
			my $mark = index( lc $title, $key );
			my $x    = $start + 1;
			foreach my $position ( 0 .. length($title) - 1 ) {
				my $glyph = substr( $title, $position, 1 );
				$self->put_attrs( $x, 0, $glyph, $position == $mark ? ( $fg // 0 ) | TB_UNDERLINE : $fg, $bg );
				$x += string_columns($glyph);
			}
		}
		my $width = string_columns($caption);
		my $free  = $self->columns - $self->_title_column( scalar @_menus );
		$self->paint_text( $self->columns - $width - 1, 0, $caption, $self->color_attr( $self->caption_color ), undef ) if $width && $width + 2 <= $free;
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::MenuBar - A row of menus at the top of the
screen

=head1 SYNOPSIS

	use Term::Fabulous::Commands;
	use Term::Fabulous::Widget::MenuBar;

	my $commands = Term::Fabulous::Commands->new(
		commands => [
			{ id => 'new',  label => 'New',  keys => ['Ctrl+N'], run => sub { new_file() } },
			{ id => 'save', label => 'Save', keys => ['Ctrl+S'], run => sub { save_file() }, enabled => sub { $modified } },
			{ id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
			{ id => 'wrap', label => 'Wrap long lines', run => sub { $wrap = !$wrap }, checked => sub { $wrap } },
		],
	);
	my $menu_bar = Term::Fabulous::Widget::MenuBar->new(
		commands => $commands,
		caption  => 'Notes',
		menus    => [
			{ title => 'File', items => [ 'new', 'save', '-', 'quit' ] },
			{ title => 'View', items => ['wrap'] },
			{ title => 'Help', items => [ { label => 'About', run => sub { show_about() } } ] },
		],
	);
	$root->add_child( $menu_bar, $content, $status_bar );

	my $ui = Term::Fabulous->new( root => $root );
	$commands->listen($root);    # Ctrl+N, Ctrl+S, Ctrl+Q
	$menu_bar->listen($root);    # F10, Alt+F, Alt+V, Alt+H
	$ui->run;

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-menu-bar.svg" alt="A notes editor with a menu bar of File, Edit, View and Help, each with its first letter underlined, and the caption notes.txt. The Edit menu is open below its title with Undo highlighted, Redo, Cut and Copy dimmed, Paste and Select all, each with its key. The status bar at the bottom says F10 opens the menus, Ctrl+Q quits. on the left and modified and Ln 6, Col 7 on the right"></p>

=end html

The program is F<examples/widgets/menu-bar.pl>, a small notes editor.
The user typed a line and pressed C<Alt+e>. Undo is the first item that
can run. Redo, Cut and Copy are dimmed, because there is nothing to
redo and no text is selected.

=head1 DESCRIPTION

A menu bar is one row of menu titles, usually the first row of the
screen. Each title opens a L<Term::Fabulous::Widget::Menu> below it,
whose items are L<commands|Term::Fabulous::Command>. Together with a
L<Term::Fabulous::Commands> table, the menus show the user what the
program can do and which keys do it, while the keys keep working
without the menus.

Each title has a I<mnemonic>, a letter of the title that is underlined.
C<Alt> with that letter opens the menu, and C<F10> opens the first one.
These two keys come from the rest of the program, so the bar needs to
hear them: L</listen> on the root does that, as
L<Term::Fabulous::Commands/listen> does for the keys of the commands.

The bar takes the keyboard focus only while a menu is open, so Tab
never stops on it. When the menu closes, the focus goes back to the
widget that had it, so the user goes on typing where they were. A click
on a title does not take the focus from that widget either (see
L<Term::Fabulous/KEYBOARD AND FOCUS>).

=head2 Keys while a menu is open

=over

=item C<Up>, C<Down>, C<Home>, C<End>, C<PageUp>, C<PageDown>, letters

Move the highlight in the menu (see L<Term::Fabulous::Widget::Menu/Keys>).

=item C<Enter>, C<Space>

Choose the highlighted item: the menu closes, the focus goes back, and
the command runs.

=item C<Left>, C<Right>, C<Shift+Tab>, C<Tab>

Open the menu to the left or to the right, going round at the ends.

=item C<Alt> with a menu's letter

Open that menu.

=item C<Escape>, C<F10>

Close the menu.

=item other keys with C<Ctrl> or C<Alt>

Close the menu and go on to the program. So C<Ctrl+S> saves even while
a menu is open.

=back

Other keys do nothing while a menu is open.

=head2 The mouse

A click on a title opens its menu, and a click on the title of the open
menu closes it. While a menu is open, moving the pointer over another
title opens that one. A click on an item chooses it, and so does
pressing the button on a title, dragging down to an item and releasing
it there. A click anywhere else closes the menu and goes on to what was
clicked.

=head2 Where the menus go

A menu opens just below its title. Near the right edge of the screen it
moves left as far as it must to stay on the screen, and when there is
no room below the bar, it opens above it. The menus float over every
other widget, dialogs included.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $menu_bar = Term::Fabulous::Widget::MenuBar->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Input/new> (C<id>,
C<layout>, C<text_color>, ...) and the ones below. C<menus> is
required, the others are optional, and unknown parameters die. Without a
C<sizing> in C<layout>, the bar is one row high and grows to the width
of its parent.

=over

=item C<menus>

A non-empty array reference of menus, from left to right, each a hash
reference:

=over

=item C<title>

The title shown in the bar, a non-empty string. Required.

=item C<key>

The mnemonic: one letter or digit of the title. Default: the first
character of the title. It is underlined in the title, and C<Alt> with
it opens the menu. Two menus with the same mnemonic die, so give one of
them another letter (C<< { title => 'Format', key => 'o' } >> next to
C<File>). When the bar has C<commands>, a mnemonic whose C<Alt> key
runs a command dies as well. C<F10> is not checked in this way, so do
not give it to a command: the command would run instead of opening the
menus.

=item C<items>

The items of the menu, as for L<Term::Fabulous::Widget::Menu/items>:
commands, ids of C<commands>, hash references and C<'-'> for
separators.

=back

=item C<commands>

A L<Term::Fabulous::Commands> table, which items given as ids are
looked up in. Default: C<undef>.

=item C<caption>

A string shown at the right end of the bar, such as the name of the
program or of the open file. Default: C<''>. It is left out when the
bar is too narrow for it.

=item C<text_color>, C<caption_color>

The colors of the titles and of the caption, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<menu_bar.text> and C<menu_bar.caption>.

=item C<highlight_text_color>, C<highlight_background_color>

The colors of the title of the open menu. Default: the theme's
C<menu_bar.highlight.text> and C<menu_bar.highlight.background>.

=back

The background is the theme's C<menu_bar.background>. The menus are
drawn in the theme's C<menu> family, like every
L<Term::Fabulous::Widget::Menu>.

=head1 METHODS

A menu bar has the methods of L<Term::Fabulous::Widget::Input> plus
these.

=head2 listen

	$menu_bar->listen( $ui->root );

Adds a C<KeyPress> listener to a widget that calls L</handle_shortcut>,
so the keys that reach that widget open the menus. Listen on the root
for keys that work everywhere. A listener cannot be taken away again.
Returns the bar.

=head2 handle_shortcut

	return Clay::UI::Enum::Result->HANDLED if $menu_bar->handle_shortcut($event);

Opens the first menu for C<F10>, or the menu of C<Alt> and a letter,
and returns 1. Returns 0 for every other key. For programs that handle
their keys in one listener of their own.

=head2 open, close

	$menu_bar->open(1);
	$menu_bar->close;

Open a menu by its index (from 0), or switch to it, and close the open
menu. C<open> dies for an index past the last menu, while the bar is
not part of a UI and while it is disabled. Both return the bar. A
disabled bar ignores the keys of L</handle_shortcut> and the mouse.

=head2 is_open, open_menu

	if ( $menu_bar->is_open ) { say 'Menu ', $menu_bar->open_menu, ' is open' }

Whether a menu is open (1 or 0), and the index of the open menu or
C<undef>.

=head2 value

	my $index = $menu_bar->value;

The index of the open menu, or C<undef>, the same as
L</is_open, open_menu>. A
menu bar is an input widget, and this is its value.

=head2 menu

	my $file_menu = $menu_bar->menu(0);

The L<Term::Fabulous::Widget::Menu> of a menu, by index. To change the
items of a menu, write its C<items>.

=head2 titles

	my @titles = $menu_bar->titles;

The titles, from left to right.

=head2 menu_for_key

	my $index = $menu_bar->menu_for_key('f');

The index of the menu whose mnemonic is a letter, or C<undef>.

=head2 caption

	$menu_bar->caption('notes.txt');

Accessor for the parameter of the same name.

=head2 caption_color, highlight_text_color, highlight_background_color

Accessors for the colors.

=head1 EVENTS

The menus of the bar are its children while they are open, so the
C<Choose> events of their items (L<Term::Fabulous::Event::Choose>)
bubble through the bar. One listener on the bar hears every choice:

	$menu_bar->on( Choose => sub ($event) {
		$status->message( $event->command->label );
		return Clay::UI::Enum::Result->CONTINUE;
	} );

=head1 KDL PROPERTIES

A menu bar is built in Perl only: its menus hold commands, which run
code that a layout file cannot express.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Menu>, L<Term::Fabulous::Commands>,
L<Term::Fabulous::Command>, L<Term::Fabulous::Widget::StatusBar>,
L<Term::Fabulous::Manual::Menus>,
L<Term::Fabulous::Cookbook::Menus/Give a program a menu bar (MenuBar, Commands)>.

=cut
