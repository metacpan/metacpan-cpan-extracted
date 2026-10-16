package Term::Fabulous::OptionList;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::OptionList :strict(params) {
	use List::Util qw(first);
	use Term::Fabulous::Check qw(boolean describe);

	field $owner :param;    # the widget class the messages name
	field @options;    # { label, value, disabled }
	field $selected;    # index into @options, or undef

	method _fail ($message) {
		die "$owner: $message";
	}

	# An option is a label (its own value), [ label, value ] or
	# { label => ..., value => ..., disabled => ... }.
	method _parsed ($option) {
		my ( $label, $value, $disabled )
			= ref $option eq 'ARRAY' && @$option == 2 ? @$option
			: ref $option eq 'HASH'                   ? @{$option}{qw(label value disabled)}
			: !ref $option                            ? ( $option, $option )
			:                                           ();
		$self->_fail( "an option must be a label, [ label, value ] or { label => ..., value => ..., disabled => ... }, got " . describe($option) )
			unless defined $label && !ref $label && !ref $value;
		$self->_fail("a hash option takes only the keys 'label', 'value' and 'disabled'")
			if ref $option eq 'HASH' && grep { !/\A(?:label|value|disabled)\z/ } keys %$option;
		return { label => "$label", value => $value // $label, disabled => boolean( $owner, 'option disabled' => $disabled ) };
	}

	method _checked_index ( $what, $index ) {
		$self->_fail( "$what needs an option index in 0.." . $#options . ", got " . describe($index) )
			unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/ && $index < @options;
		return $index + 0;
	}

	# ---------------------------------------------------------------------
	# The options
	# ---------------------------------------------------------------------

	# New options; the selected value stays selected when an option still
	# has it.
	method set_options ($list) {
		$self->_fail("options must be an array reference") unless ref $list eq 'ARRAY';
		my @parsed     = map { $self->_parsed($_) } @$list;
		my $kept_value = $self->value;
		@options  = @parsed;
		$selected = defined $kept_value ? $self->index_of_value($kept_value) : undef;
		return $self;
	}

	method options () {
		return map { +{%$_} } @options;
	}

	method count () {
		return scalar @options;
	}

	method label ($index) {
		return $options[ $self->_checked_index( label => $index ) ]{label};
	}

	method is_disabled ($index) {
		return $options[ $self->_checked_index( option_disabled => $index ) ]{disabled};
	}

	method set_disabled ( $index, $disabled ) {
		$options[ $self->_checked_index( option_disabled => $index ) ]{disabled} = boolean( $owner, 'option disabled' => $disabled );
		return $self;
	}

	method enabled_indexes () {
		return grep { !$options[$_]{disabled} } 0 .. $#options;
	}

	method index_of_value ($wanted) {
		return first { defined $options[$_]{value} && $options[$_]{value} eq $wanted } 0 .. $#options;
	}

	# ---------------------------------------------------------------------
	# The selection
	# ---------------------------------------------------------------------

	method selected_index () {
		return $selected;
	}

	method value () {
		return defined $selected ? $options[$selected]{value} : undef;
	}

	method selected_label () {
		return defined $selected ? $options[$selected]{label} : undef;
	}

	# Selects as the program does: any option, a disabled one too; undef
	# selects none.
	method set_selected_index ($index) {
		$self->_fail( "selected_index must be undef or an index in 0.." . $#options . ", got " . describe($index) )
			if defined $index && !( !ref $index && $index =~ /\A[0-9]+\z/ && $index < @options );
		$selected = defined $index ? $index + 0 : undef;
		return $self;
	}

	method set_value ($wanted) {
		my $index = defined $wanted ? $self->index_of_value($wanted) : undef;
		$self->_fail("no option has the value '$wanted'") if defined $wanted && !defined $index;
		$selected = $index;
		return $self;
	}

	# Selects as the user does: returns 1 when the selection changed, 0
	# for the selected option or a disabled one.
	method choose ($index) {
		$index = $self->_checked_index( choose => $index );
		return 0 if $options[$index]{disabled} || ( defined $selected && $selected == $index );
		$selected = $index;
		return 1;
	}

	# ---------------------------------------------------------------------
	# Layouts
	# ---------------------------------------------------------------------

	# The options of an 'options "Red" "Green"' node or of one
	# 'option "Red" value="r" disabled=#true' node.
	method from_layout_node :common ( $owner, $kid ) {
		my $name = $kid->name;
		die "$owner: layout property '$name' takes no children" if $kid->children->@*;

		my @labels = map { $_->as_perl } $kid->args->@*;
		if ( $name eq 'options' ) {
			die "$owner: layout property 'options' takes one or more labels and no properties" if !@labels || $kid->props->@*;
			return @labels;
		}
		my %props   = map  { $_->[0] => $_->[1]->as_perl } $kid->props->@*;
		my @unknown = grep { !/\A(?:value|disabled)\z/ } sort keys %props;
		die "$owner: layout property 'option' takes one label and optional value=... and disabled=..." if @labels != 1 || @unknown;
		return { label => $labels[0], value => $props{value} // $labels[0], disabled => $props{disabled} // 0 };
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::OptionList - The options of a choice and the one selected

=head1 SYNOPSIS

	use Term::Fabulous::OptionList;

	my $list = Term::Fabulous::OptionList->new( owner => 'My::Picker' );
	$list->set_options( [ 'Red', [ 'Green', 'g' ], { label => 'Blue', value => 'b', disabled => 1 } ] );

	$list->set_value('g');       # select by value (dies for an unknown one)
	$list->selected_index;       # 1
	$list->selected_label;       # 'Green'
	$list->choose(2);            # 0: Blue is disabled
	$list->choose(0);            # 1: the selection changed
	$list->enabled_indexes;      # ( 0, 1 )

=head1 DESCRIPTION

The options of a widget that chooses one of several, and which one is
selected: a L<Term::Fabulous::Widget::Dropdown> and a
L<Term::Fabulous::Widget::SegmentedControl> each hold one. It knows
nothing of widgets or events: L</choose> reports whether the selection
changed and the widget fires its C<Change> event. Errors start with the
C<owner> given to the constructor, the widget's class.

=head2 Options

An option is given as

=over

=item * a label, which is also its value: C<'Red'>;

=item * C<[ $label, $value ]>;

=item * C<< { label => $label, value => $value, disabled => $flag } >>,
where C<value> defaults to the label and C<disabled> to 0.

=back

Labels are strings; a value is a string or a number (compared as a
string), not a reference. A disabled option is shown but the user cannot
choose it (L</choose>), and the arrow keys skip it (see
L<Term::Fabulous::Roving>); the program may still select it with
L<set_value or set_selected_index|/set_selected_index, set_value>.

=head1 CONSTRUCTOR

=head2 new

	my $list = Term::Fabulous::OptionList->new( owner => ref($self) );

C<owner> is required: the name the error messages start with. The list
starts empty, with nothing selected.

=head1 METHODS

=head2 set_options

	$list->set_options( [ 'Red', 'Green' ] );

Replaces the options. When an option still has the value that was
selected, it is selected; otherwise nothing is. Dies, changing nothing,
for anything but an array reference of options (see L</Options>).
Returns the list.

=head2 options

A list of new hashes C<{ label, value, disabled }>, one per option.

=head2 count

The number of options.

=head2 label, is_disabled, set_disabled

	my $label = $list->label($index);
	$list->set_disabled( $index, 1 );

An option's label, and whether it is disabled. The index must be one of
an option.

=head2 enabled_indexes

The indexes of the options that are not disabled, in order.

=head2 index_of_value

The index of the first option with a value, or C<undef>.

=head2 selected_index, value, selected_label

The selected option's index, value and label, or C<undef> when nothing
is selected.

=head2 set_selected_index, set_value

	$list->set_selected_index(2);
	$list->set_value('g');
	$list->set_value(undef);    # nothing selected

Select as the program does: any option, disabled or not. Die for an
index outside the options (C<OWNER: selected_index must be undef or an
index in 0..N, got ...>) or a value no option has
(C<OWNER: no option has the value 'x'>). Return the list.

=head2 choose

	my $changed = $list->choose($index);

Selects as the user does: returns 1 when the selection changed, 0 for
the option already selected or a disabled one. Dies for an index outside
the options (C<OWNER: choose needs an option index in 0..N, got ...>).

=head2 from_layout_node

	my @options = Term::Fabulous::OptionList->from_layout_node( ref($self), $node );

Class method. The options a KDL property node gives:
C<options "Day" "Week"> (labels) or one
C<option "Year" value="y" disabled=#true>. Other shapes die.
L<Term::Fabulous::Role::HasOptions> reads layouts with it.

=head1 SEE ALSO

L<Term::Fabulous::Role::HasOptions>, L<Term::Fabulous::Roving>.

=cut
