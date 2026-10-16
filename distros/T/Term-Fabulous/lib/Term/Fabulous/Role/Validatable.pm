package Term::Fabulous::Role::Validatable;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

role Term::Fabulous::Role::Validatable {
	use Term::Fabulous::Check qw(boolean string);
	use Term::Fabulous::Event::ValidityChange;
	use Term::Fabulous::Validator;

	field $required         :param = 0;
	field $required_message :param = 'Please fill in this field.';

	# A Term::Fabulous::Validator, or undef: any value is fine.
	field $validator;

	# The message the last ValidityChange reported; undef until one did,
	# which counts as reported valid.
	field $reported_error;

	ADJUST :params ( :$validator = undef ) {
		$required         = boolean( $self, required => $required );
		$required_message = string( $self, required_message => $required_message );
		$self->validator_coerce($validator);
	}

	# Keeps a coerced validator without checking the value: for the
	# constructor, which runs before the value exists.
	method validator_coerce ($spec) {
		$validator = Term::Fabulous::Validator->coerce($spec);
		return;
	}

	# Called after the validator was written: a text input takes the
	# accept spec the validator suggests.
	method validator_changed () {
		return;
	}

	method required (@new) {
		return $required unless @new;
		$required = boolean( $self, required => $new[0] );
		$self->validate;
		return $required;
	}

	method required_message (@new) {
		return $required_message unless @new;
		$required_message = string( $self, required_message => $new[0] );
		$self->validate;
		return $required_message;
	}

	method validator (@new) {
		return $validator unless @new;
		$self->validator_coerce( $new[0] );
		$self->validator_changed;
		$self->validate;
		return $validator;
	}

	# Whether the value counts as not filled in: undef or the empty string.
	# A checkbox says unchecked.
	method value_is_empty () {
		my $value = $self->value;
		return !defined $value || $value eq '' ? 1 : 0;
	}

	# What is wrong with the value, or undef: an empty value is fine
	# unless required, a filled one is up to the validator.
	method error () {
		return $required ? $required_message : undef if $self->value_is_empty;
		return undef unless defined $validator;
		return $validator->check( $self->value );
	}

	method is_valid () {
		return defined $self->error ? 0 : 1;
	}

	# Reports the message when it differs from the last one reported, and
	# returns it.
	method validate () {
		my $error = $self->error;
		return $error if ( $error // '' ) eq ( $reported_error // '' );
		$reported_error = $error;
		$self->fire_event( Term::Fabulous::Event::ValidityChange->new( is_valid => defined $error ? 0 : 1, error => $error ) );
		return $error;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::Validatable - An input widget whose value can be checked

=head1 SYNOPSIS

	# Every input widget has these:
	my $field = Term::Fabulous::Widget::TextField->new( required => 1, validator => 'email' );
	my $error = $field->error;        # the message, or undef
	my $fine  = $field->is_valid;     # 1 or 0
	$field->validate;                 # fires ValidityChange when the message changed

=head1 DESCRIPTION

The role behind the C<required> and C<validator> parameters of the
input widgets. L<Term::Fabulous::Widget::Input> composes it, so every
input has them; the parameters, accessors and events are documented
there (L<Term::Fabulous::Widget::Input/required>,
L<Term::Fabulous::Widget::Input/validator>,
L<Term::Fabulous::Widget::Input/error>,
L<Term::Fabulous::Widget::Input/is_valid>,
L<Term::Fabulous::Widget::Input/validate>).

A widget of your own that is not an input may compose the role too. It
needs a C<value> method and L<Clay::UI::Role::Events::Emitter> (for
C<fire_event>). The role reads the value whenever it is asked, so the
value may change behind its back; call L<Term::Fabulous::Widget::Input/validate> when it does.

=head1 SUBCLASS INTERFACE

=head2 value_is_empty

	method value_is_empty :override () { return $checked ? 0 : 1 }

Whether the value counts as not filled in, which C<required> rejects
and the validator never sees. Default: the value is C<undef> or the
empty string. L<Term::Fabulous::Widget::Checkbox> overrides it: an
unchecked box is empty.

=head2 validator_changed

	method validator_changed :override () { ... }

Called after C<validator> was written, before the value is checked
again. Default: nothing. L<Term::Fabulous::Widget::TextInput> takes
the validator's suggested C<accept> here.

=head2 validator_coerce

	$self->validator_coerce($spec);

Keeps the coerced validator without checking the value or calling
L</validator_changed>; the constructor uses it, since the value does
not exist yet when the role's parameters are read. A class whose
constructor builds the value afterwards calls L</validator_changed>
itself when it needs the suggestion.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Input>, L<Term::Fabulous::Validator>,
L<Term::Fabulous::Event::ValidityChange>.

=cut
