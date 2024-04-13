package Tags::HTML::Element::Form;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
use Tags::HTML::Element::Utils qw(tags_data tags_value);

our $VERSION = 0.10;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['background_color'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Background color.
	$self->{'background_color'} = '#f2f2f2';

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_form'};

	return;
}

sub _init {
	my ($self, $form) = @_;

	# Check form.
	if (! defined $form
		|| ! blessed($form)
		|| ! $form->isa('Data::HTML::Element::Form')) {

		err "Form object must be a 'Data::HTML::Element::Form' instance.";
	}

	$self->{'_form'} = $form;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_form'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'form'],
		tags_value($self, $self->{'_form'}, 'css_class', 'class'),
		tags_value($self, $self->{'_form'}, 'action'),
		tags_value($self, $self->{'_form'}, 'method'),
		defined $self->{'_form'}->{'label'} ? (
			['b', 'fieldset'],
			['b', 'legend'],
			['d', $self->{'_form'}->{'label'}],
			['e', 'legend'],
		) : (),
	);
	tags_data($self, $self->{'_form'});
	$self->{'tags'}->put(
		defined $self->{'_form'}->{'label'} ? (
			['e', 'fieldset'],
		) : (),
		['e', 'form'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_form'}) {
		return;
	}

	my $css_class = '';
	if (defined $self->{'_form'}->css_class) {
		$css_class = '.'.$self->{'_form'}->css_class;
	}
	my $css_legend = $css_class;
	if ($css_legend) {
		$css_legend .= ' ';
	}
	$css_legend .= 'legend';
	my $css_fieldset = $css_class;
	if ($css_fieldset) {
		$css_fieldset .= ' ';
	}
	$css_fieldset .= 'fieldset';

	$self->{'css'}->put(
		['s', $css_class],
		['d', 'border-radius', '5px'],
		['d', 'background-color', $self->{'background_color'}],
		['d', 'padding', '20px'],
		['e'],

		['s', $css_fieldset],
		['d', 'padding', '20px'],
		['d', 'border-radius', '15px'],
		['e'],

		['s', $css_legend],
		['d', 'padding-left', '10px'],
		['d', 'padding-right', '10px'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Form - Tags helper for HTML form element.

=head1 SYNOPSIS

 use Tags::HTML::Element::Form;

 my $obj = Tags::HTML::Element::Form->new(%params);
 $obj->cleanup;
 $obj->init($form);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::Form->new(%params);

Constructor.

=over 8

=item * C<background_color>

Form background color.

Default value is '#f2f2f2'.

=item * C<css>

'L<CSS::Struct::Output>' object for L</process_css> processing.

Default value is undef.

=item * C<tags>

'L<Tags::Output>' object for L</process> processing.

Default value is undef.

=back

=head2 C<init>

 $obj->init($form);

Initialize L<Tags> structure for fields defined in C<$form>.

Accepted C<$form> is L<Data::HTML::Element::Form>.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Do nothing in this object.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure to output.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         From Tags::HTML::init():
                 Form object must be a 'Data::HTML::Element::Form' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=form_with_submit.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::Form;
 use Tags::HTML::Element::Form;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my %p = (
         'css' => $css,
         'tags' => $tags,
 );
 my $obj = Tags::HTML::Element::Form->new(%p);

 my $form = Data::HTML::Element::Form->new(
         'css_class' => 'form',
         'data' => [
                 ['b', 'p'],
                 ['b', 'button'],
                 ['a', 'type', 'submit'],
                 ['d', 'Save'],
                 ['e', 'button'],
                 ['e', 'p'],
         ],
         'data_type' => 'tags',
         'label' => 'Form for submit',
 );

 # Initialize.
 $obj->init($form);

 # Process form.
 $obj->process;
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <form class="form" method="get">
 #   <fieldset>
 #     <legend>
 #       Form for submit
 #     </legend>
 #     <p>
 #       <button type="submit">
 #         Save
 #       </button>
 #     </p>
 #   </fieldset>
 # </form>
 # 
 # .form {
 #         border-radius: 5px;
 #         background-color: #f2f2f2;
 #         padding: 20px;
 # }
 # .form fieldset {
 #         padding: 20px;
 #         border-radius: 15px;
 # }
 # .form legend {
 #         padding-left: 10px;
 #         padding-right: 10px;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>,
L<Tags::HTML::Element::Utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
