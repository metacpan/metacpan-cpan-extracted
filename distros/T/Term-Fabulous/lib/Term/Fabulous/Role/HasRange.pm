package Term::Fabulous::Role::HasRange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

role Term::Fabulous::Role::HasRange {

	# The layout properties that make the range (a class method), applied
	# together and before the others.
	method range_properties;

	# Changes the range: the given parts together, checked as a whole.
	method set_range;

	# A layout gives min, max, step, ... in any order and the value
	# anywhere among them: the range is set in one go first, so it never
	# passes through a state that is no range, and the value comes after.
	method apply_layout_settings (@settings) {
		my %in_range = map { $_ => 1 } ref($self)->range_properties;
		my %range    = map { @$_ } grep { $in_range{ $_->[0] } } @settings;
		$self->set_range(%range) if %range;
		return $self->next::method( grep { !$in_range{ $_->[0] } } @settings );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::HasRange - A widget whose range comes from a layout in one piece

=head1 SYNOPSIS

	use Object::Pad 0.825;

	class My::Dial :isa(Term::Fabulous::Widget::Display) :does(Term::Fabulous::Role::HasRange) :strict(params) {
		field $range;    # a Term::Fabulous::Range

		method range_properties :common () { return qw(min max step) }

		method set_range (%range) {
			$range->set_range(%range);
			$self->mark_changed;
			return $self;
		}
	}

=head1 DESCRIPTION

The widgets that pick a value from a L<Term::Fabulous::Range>
(L<Term::Fabulous::Widget::Slider>, L<Term::Fabulous::Widget::StarRating>,
L<Term::Fabulous::Widget::ProgressBar>) compose this role, so that a KDL
layout may give the parts of their range in any order: the parts are
collected and handed to C<set_range> in one call, before the other
properties (the C<value> among them) are applied. A range is checked as
a whole, so C<min 300; max 400;> works on a widget whose range was
C<0..100>, which applying C<min> alone could not.

=head1 REQUIRED METHODS

=head2 range_properties

	method range_properties :common () { return qw(min max step) }

A class method: the names of the layout properties that make the range.
Each must also be a layout property of the class (see
L<Term::Fabulous::Role::CanParseLayout/layout_properties>).

=head2 set_range

	method set_range (%range) { ... }

Changes the range parts given, checked as a whole. Called with the
range properties the layout gave, by their names.

=head1 METHODS

=head2 apply_layout_settings

Applies the range properties with L</set_range> in one call, then the
other settings as L<Term::Fabulous::Role::CanParseLayout> does.

=head1 SEE ALSO

L<Term::Fabulous::Range>, L<Term::Fabulous::Manual::KDL>.

=cut
