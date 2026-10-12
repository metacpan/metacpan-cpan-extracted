package Term::Fabulous::ThemeEditor::Preview;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

# The left side of the theme editor: a widget of every family, which the
# user can try out, drawn in the theme being edited.
class Term::Fabulous::ThemeEditor::Preview :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT_WRAP CLAY_TEXT_WRAP_NONE);
	use List::Util qw(max min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Theme;
	use Term::Fabulous::Widget::Accordion;
	use Term::Fabulous::Widget::Accordion::Item;
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::Checkbox;
	use Term::Fabulous::Widget::ColorPicker;
	use Term::Fabulous::Widget::Dialog;
	use Term::Fabulous::Widget::Divider;
	use Term::Fabulous::Widget::DocumentTabs;
	use Term::Fabulous::Widget::Dropdown;
	use Term::Fabulous::Widget::Image;
	use Term::Fabulous::Widget::Menu;
	use Term::Fabulous::Widget::MenuBar;
	use Term::Fabulous::Widget::ProgressBar;
	use Term::Fabulous::Widget::RadioButton;
	use Term::Fabulous::Widget::RadioGroup;
	use Term::Fabulous::Widget::RichText;
	use Term::Fabulous::Widget::ScrollBox;
	use Term::Fabulous::Widget::SegmentedControl;
	use Term::Fabulous::Widget::Slider;
	use Term::Fabulous::Widget::Spinner;
	use Term::Fabulous::Widget::StarRating;
	use Term::Fabulous::Widget::StatusBar;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Tabs;
	use Term::Fabulous::Widget::Tabs::Page;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextArea;
	use Term::Fabulous::Widget::TextField;
	use Term::Fabulous::Widget::Toast;

	use constant GALLERY_ID => 'theme-editor-preview';

	# A picture of 12 by 8 pixels, a ring of colors, for the image family.
	use constant PICTURE =>
'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAICAYAAADN5B7xAAAAlElEQVQYlYWQwQ3DMAwDzx5AAzTjZIB+9O1QmSFffTxA9sgC8QBaQH04ThOgbQwYMGlSIpg4ndk1CgDPdgtQwExS1+T+WF2jAjAAD6hAbWhRj4vBV42t/TcxA+zEjnBdAiD7rNEHbofhQ+wIqLhq5NP2r3G6uBNZRkt3cTohk6UMMEoz/YsjNqVLSyaWfsURex21vgGI6T6voY+23gAAAABJRU5ErkJggg==';

	# The sections of the gallery, in order: id, title, and the families
	# they show.
	my @SECTIONS = (
		[ palette       => 'Palette',       [] ],
		[ text          => 'Text',          ['text'] ],
		[ box           => 'Boxes',         ['box'] ],
		[ button        => 'Buttons',       ['button'] ],
		[ fields        => 'Fields',        [ 'text_input', 'scrollbar' ] ],
		[ choices       => 'Choices',       [ 'input',      'dropdown' ] ],
		[ color_picker  => 'Color picker',  [] ],
		[ tabs          => 'Tabs',          ['tabs'] ],
		[ document_tabs => 'Document tabs', ['document_tabs'] ],
		[ accordion     => 'Accordion',     ['accordion'] ],
		[ table         => 'Table',         ['table'] ],
		[ progress      => 'Progress',      [ 'progress', 'spinner' ] ],
		[ toast         => 'Messages',      ['toast'] ],
		[ menus         => 'Menus',         [ 'menu_bar', 'menu', 'status_bar' ] ],
		[ dialog        => 'Dialog',        ['dialog'] ],
		[ divider       => 'Dividers',      ['divider'] ],
		[ image         => 'Image',         ['image'] ],
		[ variants      => 'Variants',      [] ],
	);
	my %SECTION_OF_FAMILY = map {
		my $section = $_;
		map { $_ => $section->[0] } @{ $section->[2] }
	} @SECTIONS;

	# The families whose variants the gallery can show, with how it makes a
	# sample of one.
	my %SAMPLE = (
		text          => sub ($classes) { Term::Fabulous::Widget::Text->new( text => 'Text of this variant', classes => $classes ) },
		box           => sub ($classes) { _framed_box( 'A box of this variant', $classes ) },
		button        => sub ($classes) { _button( 'Button', $classes ) },
		input         => sub ($classes) { Term::Fabulous::Widget::Checkbox->new( label => 'Check box', checked => 1, classes => $classes ) },
		text_input    => sub ($classes) { Term::Fabulous::Widget::TextField->new( value => 'Text field', classes => $classes, layout => { sizing => { width => sizing_grow( 0, 30 ) } } ) },
		dropdown      => sub ($classes) { Term::Fabulous::Widget::Dropdown->new( options => [qw(First Second Third)], value => 'First', classes => $classes ) },
		progress      => sub ($classes) { Term::Fabulous::Widget::ProgressBar->new( value => 40, classes => $classes ) },
		spinner       => sub ($classes) { Term::Fabulous::Widget::Spinner->new( label => 'Spinner', running => 0, classes => $classes ) },
		divider       => sub ($classes) { Term::Fabulous::Widget::Divider->new( text  => 'Divider', classes => $classes ) },
		toast         => sub ($classes) { Term::Fabulous::Widget::Toast->new( kind => 'info', message => 'A message of this variant.', closable => 0, classes => $classes ) },
		menu_bar      => sub ($classes) { _menu_bar($classes) },
		menu          => sub ($classes) { _menu($classes) },
		status_bar    => sub ($classes) { Term::Fabulous::Widget::StatusBar->new( message => 'A status bar of this variant.', parts => [ [ 'dim', 'dim' ] ], classes => $classes ) },
		tabs          => sub ($classes) { _tabs($classes) },
		document_tabs => sub ($classes) { _document_tabs($classes) },
		accordion     => sub ($classes) { _accordion($classes) },
	);

	field %section;    # id => the section's box
	field %swatch;    # token => the box that shows its color
	field $gallery;
	field $variant_box;
	field $variant_list = "\x{0}";
	field $theme;

	ADJUST {
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$gallery = Term::Fabulous::Widget::ScrollBox->new(
			id     => GALLERY_ID,
			layout => {
				layout_direction => CLAY_TOP_TO_BOTTOM,
				sizing           => { width => sizing_grow(), height => sizing_grow() },
				padding          => { left  => 1,             right  => 1 },
				child_gap        => 1,
			},
		);
		$self->add_child($gallery);
		foreach my $definition (@SECTIONS) {
			my ( $id, $title ) = @$definition;
			my $box      = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, child_gap => 1 } );
			my $families = @{ $definition->[2] } ? ' (' . join( ', ', @{ $definition->[2] } ) . ')' : '';
			$box->add_child( Term::Fabulous::Widget::Divider->new( text => "$title$families", text_position => 'start', bold => 1 ) );
			my $build = "_build_$id";
			$box->add_child( $self->$build );
			$section{$id} = $box;
			$gallery->add_child($box);
		}
		$variant_box = $section{variants};

		weaken( my $weak_self = $self );
		$self->on( OnFocus  => sub ($event) { $weak_self->_reveal( $event->target ); return Clay::UI::Enum::Result->CONTINUE } );
		$self->on( KeyPress => sub ($event) { return $weak_self->_scroll_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
	}

	sub _column (@kids) {
		my $box = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
		$box->add_child(@kids);
		return $box;
	}

	sub _row ( $gap, @kids ) {
		my $box = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT_WRAP, sizing => { width => sizing_grow() }, child_gap => $gap } );
		$box->add_child(@kids);
		return $box;
	}

	sub _button ( $label, $classes = [], %parameters ) {
		my $button = Term::Fabulous::Widget::Button->new( classes => $classes, layout => { padding => { left => 1, right => 1 } }, %parameters );
		$button->add_child( Term::Fabulous::Widget::Text->new( text => $label ) );
		return $button;
	}

	# A box has no border.enabled: the program frames it.
	sub _framed_box ( $text, $classes = [] ) {
		my $box = Term::Fabulous::Widget::Box->new( bordered => 1, classes => $classes, layout => { sizing => { width => sizing_grow() }, padding => { left => 1, right => 1 } } );
		$box->add_child( Term::Fabulous::Widget::Text->new( text => $text ) );
		return $box;
	}

	sub _tabs ( $classes = [] ) {
		my $tabs = Term::Fabulous::Widget::Tabs->new( classes => $classes, layout => { sizing => { width => sizing_grow() } } );
		foreach my $page ( [ General => 'The general settings.' ], [ Colors => 'The colors.' ], [ Locked => 'Not available.', 1 ] ) {
			my $tab = Term::Fabulous::Widget::Tabs::Page->new( title => $page->[0], disabled => $page->[2] // 0 );
			$tab->add_child( Term::Fabulous::Widget::Text->new( text => $page->[1] ) );
			$tabs->add_child($tab);
		}
		return $tabs;
	}

	# Tabs of documents: one with unsaved changes, one with errors, one
	# that cannot be closed. A click shows a tab; closing does nothing.
	sub _document_tabs ( $classes = [] ) {
		my $tabs = Term::Fabulous::Widget::DocumentTabs->new(
			classes => $classes,
			active  => 0,
			tabs    => [ { title => 'notes' }, { title => 'draft', modified => 1 }, { title => 'broken', error => 1 }, { title => 'pinned', closable => 0 } ],
			layout  => { sizing => { width => sizing_grow() } },
		);
		weaken( my $weak_tabs = $tabs );
		$tabs->on( Select => sub ($event) { $weak_tabs->active( $event->index ); return } );
		return $tabs;
	}

	sub _accordion ( $classes = [] ) {
		my $accordion = Term::Fabulous::Widget::Accordion->new( classes => $classes, layout => { sizing => { width => sizing_grow() } } );
		foreach my $item ( [ 'Account' => 'Name, e-mail and password.' ], [ 'Notifications' => 'What reaches you, and how.' ], [ 'Privacy' => 'Who sees what.' ] ) {
			my $section = Term::Fabulous::Widget::Accordion::Item->new( title => $item->[0] );
			$section->add_child( Term::Fabulous::Widget::Text->new( text => $item->[1] ) );
			$accordion->add_child($section);
		}
		$accordion->open(0);
		return $accordion;
	}

	# ---------------------------------------------------------------------
	# The sections
	# ---------------------------------------------------------------------

	method _build_palette () {
		my $grid = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT_WRAP, sizing => { width => sizing_grow() }, child_gap => 1 } );
		foreach my $token ( Term::Fabulous::Theme::tokens() ) {
			my $color = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } );
			my $entry = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(19) }, child_gap => 1 } );
			$entry->add_child( $color, Term::Fabulous::Widget::Text->new( text => $token, wrap_mode => CLAY_TEXT_WRAP_NONE ) );
			$swatch{$token} = $color;
			$grid->add_child($entry);
		}
		return $grid;
	}

	method _build_text () {
		my $links = Term::Fabulous::Widget::RichText->new(
			markup => 'Body text in the text color, with [link=one]a link[/link] and [link=two]another one[/link]. Point at a link to see it hovered; Tab to the text and Right to select one.',
		);
		return _column( Term::Fabulous::Widget::Text->new( text => 'Plain text, as most widgets draw it.' ), $links );
	}

	method _build_box () {
		my $plain = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() } } );
		$plain->add_child( Term::Fabulous::Widget::Text->new( text => 'A box without a border shows its background only.' ) );
		return _column( _framed_box('A box with a border: box.border.color and box.border.style.'), $plain );
	}

	# The buttons as the theme draws them, and with a border of their own,
	# so that button.border.color and button.border.style show either way.
	method _build_button () {
		my $themed   = Term::Fabulous::Widget::Text->new( text => 'As the theme draws them; button.border.enabled gives them a border:' );
		my $bordered = Term::Fabulous::Widget::Text->new( text => 'With a border of their own, in button.border.color and button.border.style:' );
		return _column( $themed, _buttons(), $bordered, _buttons( bordered => 1 ) );
	}

	sub _buttons (%border) {
		return _row( 1, _button( 'Save', ['primary'], %border ), _button( 'Cancel', [], %border ), _button( 'Disabled', [], disabled => 1, %border ) );
	}

	method _build_fields () {
		my $invalid = Term::Fabulous::Widget::TextField->new( value => 'not an e-mail address', validator => 'email', layout => { sizing => { width => sizing_grow() } } );
		my $area    = Term::Fabulous::Widget::TextArea->new(
			value  => join( "\n", 'A text area with more lines', 'than it shows, so its scrollbar', 'appears at the right.', 'Scroll it with the wheel', 'or move through it', 'with the arrow keys.' ),
			layout => { sizing => { width => sizing_grow(), height => sizing_fixed(3) } },
		);
		return _column(
			Term::Fabulous::Widget::TextField->new( placeholder => 'A placeholder',                layout => { sizing => { width => sizing_grow() } } ),
			Term::Fabulous::Widget::TextField->new( value       => 'Text you can select and edit', layout => { sizing => { width => sizing_grow() } } ),
			$invalid,
			Term::Fabulous::Widget::TextField->new( value => 'Disabled', disabled => 1, layout => { sizing => { width => sizing_grow() } } ),
			$area,
		);
	}

	method _build_choices () {
		my $size = Term::Fabulous::Widget::RadioGroup->new( value => 'm', layout => { layout_direction => CLAY_LEFT_TO_RIGHT, child_gap => 2 } );
		$size->add_child( Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) ) foreach [ Small => 's' ], [ Medium => 'm' ], [ Large => 'l' ];
		return _column(
			_row(
				2, Term::Fabulous::Widget::Checkbox->new( label => 'Checked', checked => 1 ), Term::Fabulous::Widget::Checkbox->new( label => 'Not checked' ),
				Term::Fabulous::Widget::Checkbox->new( label => 'Disabled', disabled => 1 )
			),
			$size,
			Term::Fabulous::Widget::SegmentedControl->new( options => [qw(Day Week Month)], value => 'Week' ),
			Term::Fabulous::Widget::Slider->new( min => 0, max => 100, value => 65, value_format => '%d%%', layout => { sizing => { width => sizing_grow( 0, 40 ) } } ),
			Term::Fabulous::Widget::StarRating->new( value => 3.5, half => 1, show_value => 1 ),
			Term::Fabulous::Widget::Dropdown->new( options => [ 'Red', 'Green', 'Blue', 'Cyan', 'Magenta' ], value => 'Green' ),
		);
	}

	# A color picker with a few swatches; the color picker has no family
	# of its own, its parts draw in theirs.
	method _build_color_picker () {
		return Term::Fabulous::Widget::ColorPicker->new(
			id        => 'theme-editor-preview-color',
			value     => 'sky',
			list_rows => 5,
			swatches  => [ [ 'rose', 'Rose', '#e06c75' ], [ 'amber', 'Amber', '#e5c07b' ], [ 'leaf', 'Leaf', '#98c379' ], [ 'sky', 'Sky', '#61afef' ], [ 'none', 'None' ] ],
		);
	}

	method _build_tabs () {
		return _tabs();
	}

	method _build_document_tabs () {
		return _document_tabs();
	}

	method _build_accordion () {
		return _accordion();
	}

	method _build_table () {
		my @people = (
			[ 'Ada',     'Engines',   96 ], [ 'Grace',  'Compilers', 91 ], [ 'Alan',     'Engines', 88 ], [ 'Edsger', 'Compilers', 85 ],
			[ 'Barbara', 'Languages', 93 ], [ 'Donald', 'Languages', 99 ], [ 'Margaret', 'Engines', 94 ],
		);
		return Term::Fabulous::Widget::Table->new(
			id         => 'theme-editor-preview-table',
			row_id     => 'name',
			group_by   => 'team',
			selection  => 'single',
			hover      => 1,
			filter_row => 1,
			page_size  => 5,
			columns    => [ { key => 'name', title => 'Name' }, { key => 'team', title => 'Team' }, { key => 'score', title => 'Score', type => 'number' } ],
			rows       => [ map { { name => $_->[0], team => $_->[1], score => $_->[2] } } @people ],
			layout     => { sizing => { width => sizing_grow() } },
		);
	}

	method _build_progress () {
		return _column(
			Term::Fabulous::Widget::ProgressBar->new( value => 65, layout => { sizing => { width => sizing_grow( 0, 40 ) } } ),
			Term::Fabulous::Widget::ProgressBar->new( value => 30, value_position => 'inside', layout => { sizing => { width => sizing_grow( 0, 40 ) } } ),
			Term::Fabulous::Widget::Spinner->new( label => 'A spinner, stopped', running => 0 ),
		);
	}

	method _build_toast () {
		my $show = _button('Show a toast');
		weaken( my $weak_self = $self );
		$show->on( Activate => sub ($event) { $weak_self->_show_toast; return } );
		return _column(
			(
				map { Term::Fabulous::Widget::Toast->new( kind => $_->[0], title => $_->[1], message => $_->[2], closable => 0 ) } [ info => 'Info', 'Good to know.' ],
				[ success => 'Saved', 'The theme was written.' ], [ warning => 'Careful', 'It cannot be undone.' ]
			),
			Term::Fabulous::Widget::Toast->new( kind => 'danger', title => 'Important', message => 'Filled with its color.', important => 1, closable => 0 ),
			$show,
		);
	}

	# A menu bar whose titles open short menus, a menu with every kind of
	# item, and a status bar for each kind of message.
	method _build_menus () {
		return _column(
			_menu_bar( [] ),
			_row( 0, _menu( [] ) ),
			Term::Fabulous::Widget::StatusBar->new( message => 'An info message.',     parts => [ [ 'accent', 'accent' ], [ 'dim', 'dim' ] ] ),
			Term::Fabulous::Widget::StatusBar->new( message => 'Saved the theme.',     kind  => 'success' ),
			Term::Fabulous::Widget::StatusBar->new( message => 'It cannot be undone.', kind  => 'warning' ),
			Term::Fabulous::Widget::StatusBar->new( message => 'Could not write it.',  kind  => 'danger' ),
		);
	}

	sub _menu_bar ($classes) {
		return Term::Fabulous::Widget::MenuBar->new(
			caption => 'caption',
			classes => $classes,
			menus   => [ map { { title => $_, items => [ { label => 'New' }, { label => 'Open', keys => ['Ctrl+O'] } ] } } qw(File Edit View) ],
		);
	}

	# Highlighted, with keys, a separator, a toggle that is on and one that
	# is disabled.
	sub _menu ($classes) {
		return Term::Fabulous::Widget::Menu->new(
			classes => $classes,
			items   => [
				{ label => 'Highlighted', keys => ['Ctrl+H'] },
				{ label => 'With keys',   keys => ['F5'] },
				'-',
				{ label => 'Checked',  checked => sub { 1 } },
				{ label => 'Disabled', enabled => sub { 0 } },
			],
		);
	}

	method _build_dialog () {
		my $open = _button('Open a dialog');
		weaken( my $weak_self = $self );
		$open->on( Activate => sub ($event) { $weak_self->_open_dialog; return } );
		return $open;
	}

	method _build_divider () {
		return _column(
			Term::Fabulous::Widget::Divider->new,
			Term::Fabulous::Widget::Divider->new( text => 'A divider with text' ),
		);
	}

	method _build_image () {
		return _row(
			2, Term::Fabulous::Widget::Image->new( base64 => PICTURE ),
			Term::Fabulous::Widget::Text->new( text => 'Without the Imager module, a notice in image.notice is shown instead of the picture.' )
		);
	}

	method _build_variants () {
		return Term::Fabulous::Widget::Text->new( text => 'The theme defines no variants.', id => 'theme-editor-no-variants' );
	}

	# ---------------------------------------------------------------------
	# Live parts: a toast and a dialog in the preview theme
	# ---------------------------------------------------------------------

	method _show_toast () {
		my $ui    = $self->ui // return;
		my $toast = Term::Fabulous::Widget::Toast->new( kind => 'success', title => 'A toast', message => 'It closes by itself after a few seconds.' );
		$ui->add_preview_root($toast) if $ui->can('add_preview_root');
		$toast->show($ui);
		return;
	}

	method _open_dialog () {
		my $ui     = $self->ui // return;
		my $dialog = Term::Fabulous::Widget::Dialog->new(
			layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(44) }, padding => { left => 2, right => 2, top => 1, bottom => 1 }, child_gap => 1 } );
		my $close = _button( 'Close', ['primary'] );
		$close->on( Activate => sub ($event) { $dialog->close; return } );
		$dialog->add_child( Term::Fabulous::Widget::Text->new( text => 'A dialog in the preview theme, over its backdrop. Escape or the button closes it.' ), $close );
		$ui->add_preview_root($dialog) if $ui->can('add_preview_root');
		$dialog->open($ui);
		return;
	}

	# ---------------------------------------------------------------------
	# Following the theme
	# ---------------------------------------------------------------------

	# Shows a theme: the palette swatches and a sample of each variant (the
	# widgets read their looks themselves; the editor paints the screen
	# background behind them).
	# The variants come as [ family, name ] pairs.
	method show_theme ( $new, @variants ) {
		$theme = $new;
		$swatch{$_}->background_color( $theme->token($_) ) foreach keys %swatch;
		$self->_show_variants(@variants);
		return $self;
	}

	method _show_variants (@variants) {
		my $list = join ',', map { "$_->[0].$_->[1]" } @variants;
		return if $list eq $variant_list;
		$variant_list = $list;
		my @kids = @{ $variant_box->children };
		$variant_box->remove_child( @kids[ 1 .. $#kids ] );
		return $variant_box->add_child( $self->_build_variants ) unless @variants;
		foreach my $variant (@variants) {
			my ( $family, $name ) = @$variant;
			my $sample = $SAMPLE{$family};
			$variant_box->add_child(
				_column(
					Term::Fabulous::Widget::Text->new( text => "$family\[$name]" ),
					defined $sample ? $sample->( [$name] ) : Term::Fabulous::Widget::Text->new( text => "The $family family has no sample of its own here; see its section above." ),
				)
			);
		}
		return;
	}

	# ---------------------------------------------------------------------
	# Scrolling
	# ---------------------------------------------------------------------

	method section_of_family ($family) {
		return $SECTION_OF_FAMILY{$family};
	}

	# Scrolls the gallery so that a section starts at its top.
	method show_section ($id) {
		my $box = $section{$id} // return $self;
		$self->_scroll_into_view( $box, 1 );
		return $self;
	}

	method _scroll_into_view ( $widget, $to_top = 0 ) {
		my $ui       = $self->ui                   // return;
		my $view     = $ui->bounding_box($gallery) // return;
		my $target   = $ui->bounding_box($widget)  // return;
		my $state    = $ui->scroll_state($gallery) // return;
		my $position = $state->{position}{y}       // 0;
		my $top      = $view->{y};
		my $bottom   = $view->{y} + $view->{height};
		my $wanted   = $position;

		if ( $to_top || $target->{y} < $top ) {
			$wanted = $position - ( $target->{y} - $top );
		}
		elsif ( $target->{y} + $target->{height} > $bottom ) {
			$wanted = $position - ( $target->{y} + min( $target->{height}, $view->{height} ) - $bottom );
		}
		my $lowest = min( 0, $view->{height} - ( $state->{content}{height} // 0 ) );
		$wanted = max( $lowest, min( 0, $wanted ) );
		$ui->scroll_to( $gallery, { y => $wanted } ) if $wanted != $position;
		return;
	}

	method _reveal ($target) {
		return unless blessed $target && $gallery->contains($target);
		$self->_scroll_into_view($target);
		return;
	}

	# PageUp, PageDown, Ctrl+Home and Ctrl+End scroll the gallery when the
	# focused widget does not use them.
	method _scroll_key ($event) {
		my $name     = $event->main_key_name       // return 0;
		my $ui       = $self->ui                   // return 0;
		my $view     = $ui->bounding_box($gallery) // return 0;
		my $state    = $ui->scroll_state($gallery) // return 0;
		my $position = $state->{position}{y}       // 0;
		my $lowest   = min( 0, $view->{height} - ( $state->{content}{height} // 0 ) );
		my %target   = ( PageUp => $position + $view->{height} - 1, PageDown => $position - $view->{height} + 1, 'Ctrl+Home' => 0, 'Ctrl+End' => $lowest );
		return 0 unless exists $target{$name};
		$ui->scroll_to( $gallery, { y => max( $lowest, min( 0, $target{$name} ) ) } );
		return 1;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::Preview - The gallery of widgets in the
theme editor's preview

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A box with a scroll box of sections, one or more per widget
family, each under a divider that names the families it shows: the
palette (a swatch of every token), text and links, boxes, buttons,
fields (text fields with a placeholder, a selection, an invalid value
and a disabled one, a text area with a scrollbar), choices (check boxes,
radio buttons, a segmented control, a slider, a star rating, a
dropdown), a color picker with swatches, tabs, document tabs (with
unsaved changes, errors and a tab that cannot be closed), an accordion,
a table (groups, a filter row, pages), progress bars and a spinner,
toasts (and a button that shows one), a menu bar whose titles open
menus, a menu with every kind of item, a status bar for each kind of
message, a button that opens a dialog, dividers, an image, and the
variants the theme defines, each with a sample of its family.

The editor draws the gallery in the theme being edited (see
L<Term::Fabulous::ThemeEditor::UI>); the widgets read their looks
themselves. A toast or a dialog opened from the gallery draws in that
theme too.

C<PageUp>, C<PageDown>, C<Ctrl+Home> and C<Ctrl+End> scroll the
gallery when the focused widget in it does not use them, and a widget
that gets the focus is scrolled into view.

=head1 METHODS

=head2 show_theme

	$preview->show_theme( $theme, [ 'button', 'primary' ], ... );

Shows a theme: the palette swatches take its colors, and the variants
section shows a sample of each C<[ family, name ]> given.

=head2 section_of_family, show_section

	$preview->show_section( $preview->section_of_family('button') );

The section that shows a family, and scrolling so that a section
starts at the top (C<palette> and C<variants> are sections too).

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>.

=cut
