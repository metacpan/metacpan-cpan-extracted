package Term::Fabulous::ThemeEditor::Form;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

# The form mode of the theme editor: every setting of a theme in a list,
# grouped into sections (the theme node, the palette, one per family, one
# per variant), with a search field, a filter for the settings the theme
# sets and a line that explains the setting under the cursor.
class Term::Fabulous::ThemeEditor::Form :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_ALIGN_Y_CENTER);
	use List::Util qw(any first);
	use Scalar::Util qw(refaddr weaken);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Theme;
	use Term::Fabulous::Theme::Document;
	use Term::Fabulous::Widget::Checkbox;
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::ThemeEditor::SettingsList;
	use Term::Fabulous::Widget::TextField;

	use constant LIST_ID => 'theme-editor-settings';

	field $on_activate :param;    # code: the user wants to edit a setting (its key)
	field $on_cursor   :param;    # code: the cursor moved (the row's id)

	field $search   :reader;
	field $only_set :reader;
	field $list     :reader;
	field $banner;
	field $details;
	field %shown;    # id => the row data last given to the list
	field $variant_list = '';
	field $shown_tab;    # the address of the tab the rows are of
	field $read_only = 0;

	ADJUST {
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$search   = Term::Fabulous::Widget::TextField->new( placeholder => 'Search (Ctrl+F)', layout => { sizing => { width => sizing_grow() } } );
		$only_set = Term::Fabulous::Widget::Checkbox->new( label => 'Only set' );
		my $tools = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2, padding => { bottom => 1 } } );
		$tools->add_child( $search, $only_set );

		$banner  = Term::Fabulous::Widget::Text->new( text => '' );
		$details = Term::Fabulous::Widget::Text->new( text => '' );
		my $details_box = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_fixed(2) }, padding => { top => 0 } } );
		$details_box->add_child($details);

		weaken( my $weak_self = $self );    # for the list's callbacks, which it keeps
		$list = Term::Fabulous::ThemeEditor::SettingsList->new(
			id          => LIST_ID,
			on_activate => sub ($id) { $weak_self->_activate($id) },
			on_cursor   => sub ($id) { $weak_self->_cursor_moved($id) },
		);
		$self->add_child( $tools, $list, $details_box );

		$search->on( Change => sub ( $self, $event ) { $self->list->search( $event->value ); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$search->on( Submit => sub ( $self, $event ) { $self->focus_list;                    return },                                  owner => $self );
		$search->on(
			KeyPress => sub ( $self, $event ) {
				return Clay::UI::Enum::Result->CONTINUE unless ( $event->main_key_name // '' ) eq 'Down';
				$self->focus_list;
				return Clay::UI::Enum::Result->HANDLED;
			},
			owner => $self
		);
		$only_set->on( Change => sub ( $self, $event ) { $self->_filter_only_set( $event->value ); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
	}

	method _filter_only_set ($on) {
		$list->filter( only_set => $on ? sub ($row) { $row->{set} || $row->{has_set} } : undef );
		return;
	}

	method _activate ($id) {
		return unless defined $id;
		my $row = $shown{$id} // return;
		return if $row->{section};
		$on_activate->( $row->{key} );
		return;
	}

	method _cursor_moved ($id) {
		$self->_explain($id);
		$on_cursor->($id);
		return;
	}

	# ---------------------------------------------------------------------
	# Rows
	# ---------------------------------------------------------------------

	# The keys of a family's slots in every state, in the order the form
	# lists them: slots by name, each in the normal state first.
	sub slot_keys ( $family, $variant = undef ) {
		my %states_of = Term::Fabulous::Theme::slots($family);
		my @keys;
		foreach my $slot ( sort keys %states_of ) {
			push @keys, map { Term::Fabulous::Theme::Document::key_for( family => $family, variant => $variant, slot => $slot, state => $_ ) } 'normal', @{ $states_of{$slot} };
		}
		return @keys;
	}

	# The id of a section row.
	sub section_id ( $kind, @names ) {
		return join ':', "#$kind", @names;
	}

	# A section row knows what it is: its kind (theme, palette, family or
	# variant), and the family and variant it is about.
	method _section_row ( $place, $label, @children ) {
		my ( $kind, $family, $variant ) = @{$place}{qw(kind family variant)};
		return {
			id      => section_id( $kind, grep { defined } $family, $variant ),
			kind    => $kind,
			family  => $family,
			variant => $variant,
			setting => $label,
			value   => '', origin => '', swatch => '', section => 1, children => \@children,
		};
	}

	method _setting_row ( $key, $label ) {
		return { id => $key, key => $key, setting => $label, value => '', origin => '', swatch => '' };
	}

	# The rows of a document's settings, with the variants it defines and
	# those the user added without settings yet.
	method _rows ( $document, @extra_variants ) {
		my @rows = (
			$self->_section_row( { kind => 'theme' },   'Theme',   map { $self->_setting_row( "theme.$_",   $_ ) } qw(name extends) ),
			$self->_section_row( { kind => 'palette' }, 'Palette', map { $self->_setting_row( "palette.$_", $_ ) } Term::Fabulous::Theme::tokens() ),
		);
		my %variants;
		push @{ $variants{ $_->[0] } }, $_->[1] foreach $document->variants, @extra_variants;
		foreach my $family ( Term::Fabulous::Theme::families() ) {
			my @slots = map { $self->_setting_row( $_, $_ =~ s/\A\Q$family\E\.//r ) } slot_keys($family);
			my %seen;
			my @variant_rows = map {
				my $variant = $_;
				$self->_section_row(
					{ kind => 'variant', family => $family, variant => $variant }, "variant $variant",
					map { $self->_setting_row( $_, $_ =~ s/\A\Q$family\E\[\Q$variant\E\]\.//r ) } slot_keys( $family, $variant )
				)
			} grep { !$seen{$_}++ } @{ $variants{$family} // [] };
			push @rows, $self->_section_row( { kind => 'family', family => $family }, $family, @slots, @variant_rows );
		}
		return @rows;
	}

	# Shows a tab: its rows (rebuilt when the variants changed) with their
	# values, and the cursor and open sections the form had for it.
	method show ( $tab, $document, @extra_variants ) {
		my $state    = $tab->form_state;
		my $variants = join ',', map { "$_->[0]\[$_->[1]]" } $document->variants, @extra_variants;
		my $other    = !defined $shown_tab || $shown_tab != refaddr $tab;
		if ( $other || $variants ne $variant_list ) {
			my @expanded = $other ? @{ $state->{expanded} // [ section_id('theme'), section_id('palette') ] } : $self->_expanded;
			my $cursor   = $other ? $state->{cursor}                                                          : $list->cursor;
			$self->_rebuild( $document, @extra_variants );
			$variant_list = $variants;
			$shown_tab    = refaddr $tab;
			$list->expand( grep { $list->has_row($_) } @expanded );
			$self->_place_cursor($cursor) if defined $cursor;
		}
		$self->_fill($document);
		return $self;
	}

	method _expanded () {
		return grep { $list->has_row($_) && $list->is_expanded($_) } map { $_->{id} } grep { $_->{section} } values %shown;
	}

	# Remembers the cursor and the open sections for a tab before the form
	# shows another one.
	method keep_state ($tab) {
		return $self unless defined $shown_tab && $shown_tab == refaddr $tab;
		my $state = $tab->form_state;
		$state->{cursor}   = $list->cursor;
		$state->{expanded} = [ $self->_expanded ];
		return $self;
	}

	method _rebuild ( $document, @extra_variants ) {
		my @rows = $self->_rows( $document, @extra_variants );
		%shown = ();
		my @queue = @rows;
		while ( my $row = shift @queue ) {
			$shown{ $row->{id} } = $row;
			push @queue, @{ $row->{children} // [] };
		}
		$list->rows( \@rows );
		return;
	}

	# The values of every row from a document and its theme; only rows
	# whose looks changed are given to the list.
	method _fill ($document) {
		my $theme = $document->theme;
		my %has_set;
		foreach my $id ( sort keys %shown ) {
			my $row = $shown{$id};
			next if $row->{section};
			my %values = $self->_values( $document, $theme, $row->{key} );
			if ( $values{set} ) {
				my $section = $list->parent_of($id);
				while ( defined $section ) {
					$has_set{$section}++;
					$section = $list->parent_of($section);
				}
			}
			next unless any { ( $values{$_} // '' ) ne ( $row->{$_} // '' ) } keys %values;
			$list->update_row( $id, \%values );
			@{$row}{ keys %values } = values %values;
		}
		foreach my $row ( grep { $_->{section} } values %shown ) {
			my $count = $has_set{ $row->{id} } // 0;
			my $text  = $count ? "$count set" : '';
			next if $text eq $row->{value} && ( $row->{has_set} // 0 ) == ( $count ? 1 : 0 );
			$list->update_row( $row->{id}, { value => $text, has_set => $count ? 1 : 0 } );
			@{$row}{qw(value has_set)} = ( $text, $count ? 1 : 0 );
		}
		$list->refresh;
		return;
	}

	# What a row shows for a key: the value, where it comes from, the
	# swatch (a color, or the glyphs of a border style) and whether the
	# theme sets it.
	method _values ( $document, $theme, $key ) {
		my $effective = $document->effective_setting($key);
		my $spec      = $effective->{spec};
		my %origin    = ( set => 'set', default => 'default', normal => 'normal', family => 'family' );
		my %values    = (
			value  => $spec                           // '',
			origin => $origin{ $effective->{origin} } // $effective->{origin},
			set    => $effective->{origin} eq 'set' ? 1 : 0,
			swatch => '',
			color  => undef,
		);
		return %values unless defined $theme;
		my $parsed = Term::Fabulous::Theme::Document::parse_key($key);
		if ( $parsed->{section} eq 'palette' ) {
			$values{color} = $theme->token( $parsed->{token} );
			return %values;
		}
		return %values unless $parsed->{section} eq 'slot';
		my $look = $theme->look( @{$parsed}{qw(family slot state)}, defined $parsed->{variant} ? [ $parsed->{variant} ] : [] );
		if ( ref $look eq 'ARRAY' ) {
			$values{color} = $look;
		}
		elsif ( ref $look ) {
			my ( $corner, $edge, $other ) = $look->get_top_glyphs;
			$values{swatch} = "$corner$edge$other";
		}
		return %values;
	}

	# ---------------------------------------------------------------------
	# Reading and moving
	# ---------------------------------------------------------------------

	# The row under the cursor: { id, key or section }, or undef.
	method current () {
		my $id = $list->cursor // return undef;
		return $shown{$id};
	}

	method current_key () {
		my $row = $self->current // return undef;
		return $row->{key};
	}

	# The section a row belongs to (a section row is its own).
	method section_of ($id) {
		my $row = $shown{$id} // return undef;
		return $row->{section} ? $id : $list->parent_of($id);
	}

	# What a section is about: { kind, family, variant }, undef for an id
	# that is no section.
	method section_info ($id) {
		my $row = $shown{ $id // '' } // return undef;
		return undef unless $row->{section};
		return { map { $_ => $row->{$_} } qw(kind family variant) };
	}

	# The keys of the settings in a section (a family's include its
	# variants').
	method keys_in ($section) {
		my @keys;
		my @queue = $list->children_of($section);
		while ( defined( my $id = shift @queue ) ) {
			my $row = $shown{$id};
			push @keys,  $row->{key} if defined $row->{key};
			push @queue, $list->children_of($id) if $row->{section};
		}
		return @keys;
	}

	method has_row ($id) {
		return exists $shown{$id} ? 1 : 0;
	}

	# Puts the cursor on a row, opening the sections above it and clearing
	# a search or filter that hides it.
	method _place_cursor ($id) {
		return 0 unless $list->has_row($id);
		my @path;
		for ( my $parent = $list->parent_of($id); defined $parent; $parent = $list->parent_of($parent) ) {
			unshift @path, $parent;
		}
		$list->expand(@path) if @path;
		unless ( grep { $_ eq $id } $list->filtered_row_ids ) {
			$search->value('');
			$list->search('');
			$only_set->checked(0);
			$self->_filter_only_set(0);
		}
		$list->cursor($id);
		$self->_explain($id);
		return 1;
	}

	# Gives the list the focus, the cursor on the first row a search
	# left.
	method focus_list () {
		my $ui       = $self->ui // return $self;
		my @settings = grep { !$shown{$_}{section} } $list->filtered_row_ids;
		my $current  = $list->cursor // '';
		$list->cursor( $settings[0] ) if @settings && !grep { $_ eq $current } @settings;
		$ui->interaction->set_focused_widget($list);
		$self->_explain( $list->cursor );
		return $self;
	}

	method go_to ($id) {
		return $self->_place_cursor($id);
	}

	# ---------------------------------------------------------------------
	# Read-only while the text has errors
	# ---------------------------------------------------------------------

	method read_only (@new) {
		return $read_only unless @new;
		$read_only = $new[0] ? 1 : 0;
		return $read_only;
	}

	method show_banner ($markup) {
		$banner->markup($markup);
		$self->insert_children( 1, $banner ) unless $self->has_child($banner);
		return $self;
	}

	method hide_banner () {
		$self->remove_child($banner);
		return $self;
	}

	# ---------------------------------------------------------------------
	# The line under the list
	# ---------------------------------------------------------------------

	field $explain_with;    # code: ( $row ) -> markup of the details line

	method explain_with ($code) {
		$explain_with = $code;
		return $self;
	}

	method _explain ($id) {
		my $row = defined $id ? $shown{$id} : undef;
		$details->markup( defined $row && defined $explain_with ? $explain_with->($row) : '' );
		return;
	}

	method explain_current () {
		$self->_explain( $list->cursor );
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::Form - The form mode of the theme editor

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A L<Term::Fabulous::ThemeEditor::SettingsList> that lists every
setting a theme can have, in sections: the C<theme> node (name and base), the
palette, one section per family with every slot in every state, and in
a family's section one per variant. Each row shows a swatch (the color,
or the corner and edge of a border style), the setting, its value and
where the value comes from: C<set> when the theme sets it, the base
theme (C<dark> or C<light>) for a palette token it does not set,
C<default> for the vocabulary's default, C<normal> for a state that
looks like the normal state, C<family> for a variant's slot that
follows its family. Rows the theme sets are bold; a section row shows
how many settings in it are set.

Above the list, a search field filters the rows by any text in them,
and C<Only set> hides the settings the theme does not set. Below it, a
line explains the setting under the cursor.

=head1 CONSTRUCTOR

=head2 new

	my $form = Term::Fabulous::ThemeEditor::Form->new(
		on_activate => sub ($key) { ... },    # Enter or a double click on a setting
		on_cursor   => sub ($id)  { ... },    # the cursor moved
	);

=head1 METHODS

=head2 show

	$form->show( $tab, $document, @extra_variants );

Shows a tab's document, with C<[ family, name ]> pairs of variants that
have no settings yet. The rows are built again when the tab or its
variants changed; otherwise only the rows whose values changed are
updated.

=head2 keep_state

Remembers the cursor and the open sections in the tab's
C<form_state>, before another tab is shown.

=head2 current, current_key

The row under the cursor (a hash reference with C<id> and C<key> or
C<section>), and its setting key.

=head2 section_of, keys_in, has_row

The section of a row, the setting keys inside a section, and whether
a row exists.

=head2 section_info

	my $info = $form->section_info( $form->section_of($id) );    # { kind => 'variant', family => 'button', variant => 'primary' }

What a section is about: its C<kind> (C<theme>, C<palette>, C<family>
or C<variant>) and the C<family> and C<variant> it belongs to (C<undef>
where the kind has none), as a new hash; C<undef> for an id that is no
section.

=head2 focus_list

Gives the list the focus; the cursor goes to the first setting the list
shows when it is not on a setting the list shows (after a search, say).

=head2 go_to

Puts the cursor on a row, opening the sections above it and clearing
a search or filter that hides it.

=head2 read_only, show_banner, hide_banner

Whether the form takes changes, and a banner (rich markup) above the
list.

=head2 explain_with, explain_current

The code that writes the line below the list for a row, and a call to
write it again.

=head2 search, only_set, list

The search field, the C<Only set> check box and the list.

=head1 FUNCTIONS

=head2 slot_keys

	my @keys = Term::Fabulous::ThemeEditor::Form::slot_keys( 'button', 'primary' );

The keys of a family's (or a variant's) slots in every state, in the
order the form lists them.

=head2 section_id

	my $id = Term::Fabulous::ThemeEditor::Form::section_id( 'family', 'button' );    # '#family:button'

The row id of a section: C<theme>, C<palette>, C<family> with its
name, or C<variant> with the family and the variant's name.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>, L<Term::Fabulous::ThemeEditor::SettingsList>.

=cut
