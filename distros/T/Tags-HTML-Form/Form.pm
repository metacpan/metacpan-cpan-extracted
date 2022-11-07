package Tags::HTML::Form;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Data::HTML::Button;
use Data::HTML::Form;
use Error::Pure qw(err);
use List::Util qw(first);
use Scalar::Util qw(blessed);
use Tags::HTML::Form::Input;
use Tags::HTML::Form::Select;

our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['form', 'input', 'select', 'submit'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Form.
	$self->{'form'} = Data::HTML::Form->new(
		'css_class' => 'form',
	);

	# Input object.
	$self->{'input'} = undef;

	# Select object.
	$self->{'select'} = undef;

	# Submit.
	$self->{'submit'} = Data::HTML::Button->new(
		'data' => [
			['d', 'Save'],
		],
		'data_type' => 'tags',
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

	# Input object.
	if (! defined $self->{'input'}) {
		$self->{'input'} = Tags::HTML::Form::Input->new(
			'css' => $self->{'css'},
			'tags' => $self->{'tags'},
		);
	} else {
		if (! blessed($self->{'input'}) || $self->{'input'}->isa('Tags::HTML::Form::Input')) {
			err "Parameter 'input' must be a 'Tags::HTML::Form::Input' instance.";
		}
	}

	# Select object.
	if (! defined $self->{'select'}) {
		$self->{'select'} = Tags::HTML::Form::Select->new(
			'css' => $self->{'css'},
			'tags' => $self->{'tags'},
		),
	} else {
		if (! blessed($self->{'select'}) || $self->{'select'}->isa('Tags::HTML::Form::Select')) {
			err "Parameter 'select' must be a 'Tags::HTML::Form::Select' instance.";
		}
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
			&& ! $field->isa('Data::HTML::Textarea')
			&& ! $field->isa('Data::HTML::Form::Select'))) {

			err "Form item must be a 'Data::HTML::Form::Input', ".
				"'Data::HTML::Textarea' or 'Data::HTML::Form::Select' instance.";
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

		defined $self->{'form'}->{'label'} ? (
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
			defined $field->label ? (
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
		);

		if ($field->isa('Data::HTML::Form::Input')) {
			$self->{'input'}->process($field);
		} elsif ($field->isa('Data::HTML::Form::Select')) {
			$self->{'select'}->process($field);
		} else {
			$self->_tags_textarea($field);
		}
	}

	if (@fields) {
		$self->{'tags'}->put(
			['e', 'p'],
		);
	}

	$self->{'tags'}->put(
		['b', 'p'],
	);
	if ($self->{'submit'}->isa('Data::HTML::Form::Input')) {
		$self->{'input'}->process($self->{'submit'});
	} else {
		$self->_tags_button($self->{'submit'});
	}
	$self->{'tags'}->put(
		['e', 'p'],

		defined $self->{'form'}->{'label'} ? (
			['e', 'fieldset'],
		) : (),
		['e', 'form'],
	);

	return;
}

sub _process_css {
	my ($self, @fields) = @_;

	$self->{'css'}->put(
		['s', '.'.$self->{'form'}->css_class],
		['d', 'border-radius', '5px'],
		['d', 'background-color', '#f2f2f2'],
		['d', 'padding', '20px'],
		['e'],

		['s', '.'.$self->{'form'}->css_class.' textarea'],
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

	# TODO Different objects and different CSS?
	my $first_input = first { ref $_ eq 'Data::HTML::Form::Input' } @fields;
	if (defined $first_input) {
		$self->{'input'}->process_css($first_input);
	}
	my $first_select = first { ref $_ eq 'Data::HTML::Form::Select' } @fields;
	if (defined $first_select) {
		$self->{'select'}->process_css($first_select);
	}

	return;
}

sub _tags_button {
	my ($self, $object) = @_;

	$self->{'tags'}->put(
		['b', 'button'],
		['a', 'type', $object->type],
		defined $object->name ? (
			['a', 'name', $object->name],
		) : (),
		defined $object->value ? (
			['a', 'value', $object->value],
		) : (),
	);
	if ($object->data_type eq 'tags') {
		$self->{'tags'}->put(@{$object->data});
	} else {
		$self->{'tags'}->put(
			['d', $object->data],
		);
	}
	$self->{'tags'}->put(
		['e', 'button'],
	);

	return;
}

sub _tags_textarea {
	my ($self, $object) = @_;

	$self->{'tags'}->put(
		['b', 'textarea'],
		defined $object->css_class ? (
			['a', 'class', $object->css_class],
		) : (),
		defined $object->id ? (
			['a', 'name', $object->id],
			['a', 'id', $object->id],
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
		defined $object->value ? (
			['d', $object->value],
		) : (),
		['e', 'textarea'],
	);

	return;
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
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Parameter 'form' is required.
         Parameter 'form' must be a 'Data::HTML::Form' instance.
         Parameter 'form' must define 'css_class' parameter.
         Parameter 'input' must be a 'Tags::HTML::Form::Input' instance.
         Parameter 'submit' instance has bad type.
         Parameter 'submit' is required.
         Parameter 'submit' must be a 'Data::HTML::Form::Input' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Form item must be a 'Data::HTML::Form::Input' instance.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

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

 # Process form.
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
L<List::Util>,
L<Scalar::Util>,
L<Tags::HTML>,
L<Tags::HTML::Form::Input>,
L<Tags::HTML::Form::Select>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Form>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
