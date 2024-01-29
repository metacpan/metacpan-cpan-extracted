package Tags::HTML::Element::Option;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.02;

sub _cleanup {
	my $self = shift;

	delete $self->{'_option'};

	return;
}

sub _init {
	my ($self, $option) = @_;

	# Check input.
	if (! defined $option
		|| ! blessed($option)
		|| ! $option->isa('Data::HTML::Element::Option')) {

		err "Option object must be a 'Data::HTML::Element::Option' instance.";
	}

	$self->{'_option'} = $option;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_option'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'option'],
		defined $self->{'_option'}->css_class ? (
			['a', 'class', $self->{'_option'}->css_class],
		) : (),
		defined $self->{'_option'}->id ? (
			['a', 'name', $self->{'_option'}->id],
			['a', 'id', $self->{'_option'}->id],
		) : (),
		$self->{'_option'}->disabled ? (
			['a', 'disabled', 'disabled'],
		) : (),
		$self->{'_option'}->selected ? (
			['a', 'selected', 'selected'],
		) : (),
		defined $self->{'_option'}->value ? (
			['a', 'value', $self->{'_option'}->value],
		) : (),
		# TODO Other. https://www.w3schools.com/tags/tag_option.asp
	);
	if ($self->{'_option'}->data_type eq 'plain') {
		$self->{'tags'}->put(
			['d', $self->{'_option'}->data],
		);
	} elsif ($self->{'_option'}->data_type eq 'tags') {
		$self->{'tags'}->put($self->{'_option'}->data);
	}
	$self->{'tags'}->put(
		['e', 'option'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_option'}) {
		return;
	}

	my $css_class = '';
	if (defined $self->{'_option'}->css_class) {
		$css_class = '.'.$self->{'_option'}->css_class;
	}

	$self->{'css'}->put(
		# TODO Implement consistent CSS.
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Option - Tags helper for HTML option element.

=head1 SYNOPSIS

 use Tags::HTML::Element::Option;

 my $obj = Tags::HTML::Element::Option->new(%params);
 $obj->process($input);
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::Option->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process($option);

Process Tags structure for C<$option> to output.

Accepted C<$option> is L<Data::HTML::Element::Option>.

Returns undef.

=head2 C<process_css>

 $obj->process_css($option);

Process CSS::Struct structure for C<$option> to output.

Accepted C<$option> is L<Data::HTML::Element::Option>.

Returns undef.

=head1 ERRORS

 new():
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Input object must be a 'Data::HTML::Element::Option' instance.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.
         Input object must be a 'Data::HTML::Element::Option' instance.

=head1 EXAMPLE

=for comment filename=create_and_print_option.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::Option;
 use Tags::HTML::Element::Option;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Element::Option->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for option.
 my $option = Data::HTML::Element::Option->new(
         'css_class' => 'form-option',
         'data' => 'Option',
 );

 # Process option.
 $obj->process($option);
 $obj->process_css($option);

 # Print out.
 print "HTML:\n";
 print $tags->flush;
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <option class="form-option">
 #   Option
 # </option>
 #
 # CSS:
 # TODO

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Element>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
