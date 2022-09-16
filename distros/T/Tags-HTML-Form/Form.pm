package Tags::HTML::Form;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Data::HTML::Button;
use Data::HTML::Form;
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['form', 'submit'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Form.
	$self->{'form'} = Data::HTML::Form->new(
		'css_class' => 'form',
	);

	# Submit.
	$self->{'submit'} = Data::HTML::Button->new(
		'data' => [
			['d', 'Save'],
		],
		'type' => 'submit',
	);

	# Process params.
	set_params($self, @{$object_params_ar});

	# Check form.
	if (! defined $self->{'form'}) {
		err "Parameter 'form' is required.";
	}
	if (! blessed($self->{'form'})
		|| ! $self->{'form'}->isa('Data::HTML::Form')) {

		err "Parameter 'form' must be a 'Data::HTML::Form' instance.";
	}
	if (! defined $self->{'form'}->{'css_class'}) {
		err "Parameter 'form' must define 'css_class' parameter.";
	}

	# Check submit.
	if (! defined $self->{'submit'}) {
		err "Parameter 'submit' is required.";
	}
	if (! blessed($self->{'submit'})
		|| (! $self->{'submit'}->isa('Data::HTML::Form::Input')
		&& ! $self->{'submit'}->isa('Data::HTML::Button'))) {

		err "Parameter 'submit' must be a 'Data::HTML::Form::Input' instance.";
	}
	if ($self->{'submit'}->type ne 'submit') {
		err "Parameter 'submit' instance has bad type.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my ($self, @fields) = @_;

	# Check fields.
	foreach my $field (@fields) {
		if (! defined $field
			|| ! blessed($field)
			|| (! $field->isa('Data::HTML::Form::Input')
			&& ! $field->isa('Data::HTML::Textarea'))) {

			err "Form item must be a 'Data::HTML::Form::Input' instance.";
		}
	}

	$self->{'tags'}->put(
		['b', 'form'],
		defined $self->{'form'}->css_class ? (
			['a', 'class', $self->{'form'}->css_class],
		) : (),
		defined $self->{'form'}->action ? (
			['a', 'action', $self->{'form'}->action],
		) : (),
		['a', 'method', $self->{'form'}->method],

		$self->{'form'}->{'label'} ? (
			['b', 'fieldset'],
			['b', 'legend'],
			['d', $self->{'form'}->{'label'}],
			['e', 'legend'],
		) : (),
	);

	if (@fields) {
		$self->{'tags'}->put(
			['b', 'p'],
		);
	}

	foreach my $field (@fields) {
		$self->{'tags'}->put(
			$field->label ? (
				['b', 'label'],
				$field->id ? (
					['a', 'for', $field->id],
				) : (),
				['d', $field->label],
				$field->required ? (
					['b', 'span'],
					['a', 'class', $self->{'form'}->css_class.'-required'],
					['d', '*'],
					['e', 'span'],
				) : (),
				['e', 'label'],
			) : (),

			$field->isa('Data::HTML::Form::Input') ? (
				$self->_tags_input($field),
			) : (
				$self->_tags_textarea($field),
			),
		);
	}

	if (@fields) {
		$self->{'tags'}->put(
			['e', 'p'],
		);
	}

	$self->{'tags'}->put(
		['b', 'p'],
		$self->{'submit'}->isa('Data::HTML::Form::Input') ? (
			$self->_tags_input($self->{'submit'}),
		) : (
			$self->_tags_button($self->{'submit'}),
		),
		['e', 'p'],

		$self->{'form'}->{'label'} ? (
			['e', 'fieldset'],
		) : (),
		['e', 'form'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'form'}->css_class],
		['d', 'border-radius', '5px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['e'],

		['s', '.'.$self->{'form'}->css_class.' input[type=submit]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', '.'.$self->{'form'}->css_class.' input[type=submit]'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', '.'.$self->{'form'}->css_class.' input, select, textarea'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],

		['s', '.'.$self->{'form'}->css_class.'-required'],
		['d', 'color', 'red'],
		['e'],
	);

	return;
}

sub _tags_button {
	my ($self, $object) = @_;

	return (
		['b', 'button'],
		['a', 'type', $self->{'submit'}->type],
		defined $self->{'submit'}->name ? (
			['a', 'name', $self->{'submit'}->name],
		) : (),
		defined $self->{'submit'}->value ? (
			['a', 'value', $self->{'submit'}->value],
		) : (),
		@{$self->{'submit'}->data},
		['e', 'button'],
	);
}

sub _tags_input {
	my ($self, $object) = @_;

	return (
		['b', 'input'],
		defined $object->css_class ? (
			['a', 'class', $object->css_class],
		) : (),
		['a', 'type', $object->type],
		defined $object->id ? (
			['a', 'name', $object->id],
			['a', 'id', $object->id],
		) : (),
		defined $object->value ? (
			['a', 'value', $object->value],
		) : (),
		defined $object->checked ? (
			['a', 'checked', 'checked'],
		) : (),
		defined $object->placeholder ? (
			['a', 'placeholder', $object->placeholder],
		) : (),
		defined $object->size ? (
			['a', 'size', $object->size],
		) : (),
		defined $object->readonly ? (
			['a', 'readonly', 'readonly'],
		) : (),
		defined $object->disabled ? (
			['a', 'disabled', 'disabled'],
		) : (),
		defined $object->min ? (
			['a', 'min', $object->min],
		) : (),
		defined $object->max ? (
			['a', 'max', $object->max],
		) : (),
		['e', 'input'],
	);
}

sub _tags_textarea {
	my ($self, $object) = @_;

	return (
		['b', 'textarea'],
		defined $object->css_class ? (
			['a', 'class', $object->css_class],
		) : (),
		defined $object->id ? (
			['a', 'name', $object->id],
			['a', 'id', $object->id],
		) : (),
		defined $object->value ? (
			['a', 'value', $object->value],
		) : (),
		defined $object->placeholder ? (
			['a', 'placeholder', $object->placeholder],
		) : (),
		defined $object->readonly ? (
			['a', 'readonly', 'readonly'],
		) : (),
		defined $object->disabled ? (
			['a', 'disabled', 'disabled'],
		) : (),
		defined $object->cols ? (
			['a', 'cols', $object->cols],
		) : (),
		defined $object->rows ? (
			['a', 'rows', $object->rows],
		) : (),
		['e', 'textarea'],
	);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Form - Tags helper for form.

=head1 SYNOPSIS

 use Tags::HTML::Form;

 my $obj = Tags::HTML::Form->new(%params);
 $obj->process(@fields);
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Form->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<form>

Data object for form.

Could ve a 'Data::HTML::Form' instance.

Default value is instance with 'form' css class.

=item * C<submit>

Data object for submit.

Could be a 'Data::HTML::Form::Input' or 'Data::HTML::Button' instance.

Default value is instance with 'Save' submit value.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process(@fields);

Process Tags structure for fields defined in C<@fields> to output.

Accepted items in C<@fields> are objects:

=over

=item * L<Data::HTML::Form::Input>

=item * L<Data::HTML::Textarea>

=back

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Parameter 'form' is required.
         Parameter 'form' must be a 'Data::HTML::Form' instance.
         Parameter 'form' must define 'css_class' parameter.
         Parameter 'submit' instance has bad type.
         Parameter 'submit' is required.
         Parameter 'submit' must be a 'Data::HTML::Form::Input' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
                 Form item must be a 'Data::HTML::Form::Input' instance.

=head1 EXAMPLE

=for comment filename=default_form.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Form;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Form->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process pager.
 $obj->process;
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <form class="form" method="GET">
 #   <p>
 #     <button type="submit">
 #       Save
 #     </button>
 #   </p>
 # </form>
 # 
 # .form {
 #         border-radius: 5px;
 #         background-color: #f2f2f2;
 #         padding: 20px;
 # }
 # .form input[type=submit]:hover {
 #         background-color: #45a049;
 # }
 # .form input[type=submit] {
 #         width: 100%;
 #         background-color: #4CAF50;
 #         color: white;
 #         padding: 14px 20px;
 #         margin: 8px 0;
 #         border: none;
 #         border-radius: 4px;
 #         cursor: pointer;
 # }
 # .form input, select, textarea {
 #         width: 100%;
 #         padding: 12px 20px;
 #         margin: 8px 0;
 #         display: inline-block;
 #         border: 1px solid #ccc;
 #         border-radius: 4px;
 #         box-sizing: border-box;
 # }
 # .form-required {
 #         color: red;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::HTML::Form>,
L<Data::HTML::Button>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Form>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
