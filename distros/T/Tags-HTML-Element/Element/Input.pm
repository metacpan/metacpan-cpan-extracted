package Tags::HTML::Element::Input;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
use Tags::HTML::Element::Utils qw(tags_boolean tags_label tags_value);

our $VERSION = 0.10;

sub _cleanup {
	my $self = shift;

	delete $self->{'_input'};

	return;
}

sub _init {
	my ($self, $input) = @_;

	# Check input.
	if (! defined $input
		|| ! blessed($input)
		|| ! $input->isa('Data::HTML::Element::Input')) {

		err "Input object must be a 'Data::HTML::Element::Input' instance.";
	}

	$self->{'_input'} = $input;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! $self->{'_input'}) {
		return;
	}

	$self->{'tags'}->put(
		tags_label($self, $self->{'_input'}),
		['b', 'input'],
		tags_boolean($self, $self->{'_input'}, 'autofocus'),
		tags_value($self, $self->{'_input'}, 'css_class', 'class'),
		tags_value($self, $self->{'_input'}, 'type'),
		tags_value($self, $self->{'_input'}, 'id'),
		tags_value($self, $self->{'_input'}, 'name'),
		tags_value($self, $self->{'_input'}, 'value'),
		tags_boolean($self, $self->{'_input'}, 'checked'),
		tags_value($self, $self->{'_input'}, 'placeholder'),
		tags_value($self, $self->{'_input'}, 'size'),
		tags_boolean($self, $self->{'_input'}, 'readonly'),
		tags_boolean($self, $self->{'_input'}, 'disabled'),
		tags_value($self, $self->{'_input'}, 'min'),
		tags_value($self, $self->{'_input'}, 'max'),
		tags_value($self, $self->{'_input'}, 'step'),
		tags_value($self, $self->{'_input'}, 'onclick'),
		['e', 'input'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! $self->{'_input'}) {
		return;
	}

	my $css_class = '';
	my $css_required = '.';
	if (defined $self->{'_input'}->css_class) {
		$css_class = '.'.$self->{'_input'}->css_class;
		$css_required .= $self->{'_input'}->css_class.'-';
	}
	$css_required .= 'required';

	$self->{'css'}->put(
		['s', 'input'.$css_class.'[type=submit]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', 'input'.$css_class.'[type=submit]'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', 'input'.$css_class.'[type=submit][disabled=disabled]'],
		['d', 'background-color', '#888888'],
		['e'],

		['s', 'input'.$css_class.'[type=text]'],
		['s', 'input'.$css_class.'[type=date]'],
		['s', 'input'.$css_class.'[type=number]'],
		['s', 'input'.$css_class.'[type=email]'],
		['s', 'input'.$css_class.'[type=checkbox]'],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],

		['s', 'input'.$css_class.'[type=button]'],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', 'input'.$css_class.'[type=button]:hover'],
		['d', 'background-color', '#45a049'],
		['e'],

		['s', $css_required],
		['d', 'color', 'red'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Input - Tags helper for HTML input element.

=head1 SYNOPSIS

 use Tags::HTML::Element::Input;

 my $obj = Tags::HTML::Element::Input->new(%params);
 $obj->cleanup;
 $obj->init($input);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::Input->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Cleanup internal structures.

Returns undef.

=head2 C<init>

 $obj->init($input);

Initialize object.

Accepted C<$input> is L<Data::HTML::Element::Input>.

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
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Input object must be a 'Data::HTML::Element::Input' instance.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.
         Input object must be a 'Data::HTML::Element::Input' instance.

=head1 EXAMPLE

=for comment filename=create_and_print_input.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::Input;
 use Tags::HTML::Element::Input;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Element::Input->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for input.
 my $input = Data::HTML::Element::Input->new(
         'css_class' => 'form-input',
 );

 # Initialize.
 $obj->init($input);

 # Process input.
 $obj->process;
 $obj->process_css;

 # Print out.
 print "HTML:\n";
 print $tags->flush;
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <input class="form-input" type="text" />
 #
 # CSS:
 # input.form-input[type=submit]:hover {
 #         background-color: #45a049;
 # }
 # input.form-input[type=submit] {
 #         width: 100%;
 #         background-color: #4CAF50;
 #         color: white;
 #         padding: 14px 20px;
 #         margin: 8px 0;
 #         border: none;
 #         border-radius: 4px;
 #         cursor: pointer;
 # }
 # input.form-input {
 #         width: 100%;
 #         padding: 12px 20px;
 #         margin: 8px 0;
 #         display: inline-block;
 #         border: 1px solid #ccc;
 #         border-radius: 4px;
 #         box-sizing: border-box;
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
