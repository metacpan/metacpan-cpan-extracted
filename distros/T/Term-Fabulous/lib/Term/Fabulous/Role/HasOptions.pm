package Term::Fabulous::Role::HasOptions;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::OptionList;

role Term::Fabulous::Role::HasOptions {

	# Reads the options without an argument, replaces them with an array
	# reference.
	method options;

	# The options of a layout come first, so value and selected_index can
	# name one wherever they stand.
	method apply_layout_settings (@settings) {
		my %is_option = ( options => 1, option => 1 );
		return $self->next::method( ( grep { $is_option{ $_->[0] } } @settings ), ( grep { !$is_option{ $_->[0] } } @settings ) );
	}

	# The handler of the 'options' and 'option' layout properties: adds
	# the options of the node.
	method add_layout_options ($kid) {
		return $self->options( [ $self->options, Term::Fabulous::OptionList->from_layout_node( ref $self, $kid ) ] );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::HasOptions - A widget whose options come from a layout

=head1 SYNOPSIS

	class My::Picker :isa(Term::Fabulous::Widget::Input) :does(Term::Fabulous::Role::HasOptions) :strict(params) {
		field $list = Term::Fabulous::OptionList->new( owner => __CLASS__ );

		method options (@new) {
			return $list->options unless @new;
			$list->set_options( $new[0] );
			$self->mark_changed;
			return $list->options;
		}

		method layout_properties :common () {
			return (
				$class->SUPER::layout_properties,
				value => 'scalar',
				options => \&add_layout_options,
				option  => \&add_layout_options,
			);
		}
	}

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Dropdown> and
L<Term::Fabulous::Widget::SegmentedControl> compose this role so that a
KDL layout gives their options in the same way, in either form, and
before the C<value> or C<selected_index> that picks one, wherever these
stand in the layout:

=for highlighter language=kdl

	options "Day" "Week" "Month"
	option "Year" value="y" disabled=#true
	value "y"

=head1 REQUIRED METHODS

=head2 options

The options accessor: without an argument the options (as
L<Term::Fabulous::OptionList/options> returns them), with an array
reference the new options.

=head1 METHODS

=head2 apply_layout_settings

Applies the C<options> and C<option> properties first, then the others,
as L<Term::Fabulous::Role::CanParseLayout> does.

=head2 add_layout_options

	$self->add_layout_options($node);

Adds the options of an C<options> or C<option> property node (see
L<Term::Fabulous::OptionList/from_layout_node>) after the ones the
widget has. The class lists it as the handler of both properties in its
C<layout_properties>.

=head1 SEE ALSO

L<Term::Fabulous::OptionList>, L<Term::Fabulous::Manual::KDL>.

=cut
