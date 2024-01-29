package Tags::HTML::Element::Select;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
use Tags::HTML::Element::Option;

our $VERSION = 0.02;

sub _cleanup {
	my $self = shift;

	delete $self->{'_select'};

	return;
}

sub _init {
	my ($self, $select) = @_;

	# Check input.
	if (! defined $select
		|| ! blessed($select)
		|| ! $select->isa('Data::HTML::Element::Select')) {

		err "Select object must be a 'Data::HTML::Element::Select' instance.";
	}

	$self->{'_select'} = $select;

	$self->{'_option'} = Tags::HTML::Element::Option->new(
		'css' => $self->{'css'},
		'tags' => $self->{'tags'},
	);

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_select'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'select'],
		defined $self->{'_select'}->css_class ? (
			['a', 'class', $self->{'_select'}->css_class],
		) : (),
		defined $self->{'_select'}->id ? (
			['a', 'name', $self->{'_select'}->id],
			['a', 'id', $self->{'_select'}->id],
		) : (),
		defined $self->{'_select'}->size ? (
			['a', 'size', $self->{'_select'}->size],
		) : (),
		$self->{'_select'}->disabled ? (
			['a', 'disabled', 'disabled'],
		) : (),
		# TODO Other. https://www.w3schools.com/tags/tag_select.asp
	);
	foreach my $option (@{$self->{'_select'}->options}) {
		$self->{'_option'}->init($option);
		$self->{'_option'}->process;
	}
	$self->{'tags'}->put(
		['e', 'select'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_select'}) {
		return;
	}

	my $css_class = '';
	if (defined $self->{'_select'}->css_class) {
		$css_class = '.'.$self->{'_select'}->css_class;
	}

	$self->{'css'}->put(
		['s', 'select'.$css_class],
		['d', 'width', '100%'],
		['d', 'padding', '12px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'display', 'inline-block'],
		['d', 'border', '1px solid #ccc'],
		['d', 'border-radius', '4px'],
		['d', 'box-sizing', 'border-box'],
		['e'],
	);
	if (@{$self->{'_select'}->options}) {
		$self->{'_option'}->process_css;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Select - Tags helper for HTML select element.

=head1 SYNOPSIS

 use Tags::HTML::Element::Select;

 my $obj = Tags::HTML::Element::Select->new(%params);
 $obj->process($select);
 $obj->process_css($select);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::Select->new(%params);

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

 $obj->process($select);

Process Tags structure for C<$select> data object to output.

Accepted C<$select> is L<Data::HTML::Element::Select>.

Returns undef.

=head2 C<process_css>

 $obj->process_css($select);

Process CSS::Struct structure for C<$select> data object to output.

Accepted C<$select> is L<Data::HTML::Element::Select>.

Returns undef.

=head1 ERRORS

 new():
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Input object must be a 'Data::HTML::Element::Select' instance.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.
         Input object must be a 'Data::HTML::Element::Select' instance.

=head1 EXAMPLE

=for comment filename=create_and_print_select.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::Select;
 use Tags::HTML::Element::Select;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Element::Select->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for select.
 my $select = Data::HTML::Element::Select->new(
         'css_class' => 'form-select',
 );

 # Process select.
 $obj->process($select);
 $obj->process_css($select);

 # Print out.
 print "HTML:\n";
 print $tags->flush;
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <select class="form-select" type="text" />
 #
 # CSS:
 # select.form-select {
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
L<Tags::HTML::Element::Option>.

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
