package Tags::HTML::Form::Select;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
use Tags::HTML::Form::Select::Option;

our $VERSION = 0.08;

sub new {
	my ($class, @params) = @_;

	my $self = $class->SUPER::new(@params);

	$self->{'_option'} = Tags::HTML::Form::Select::Option->new(
		'css' => $self->{'css'},
		'tags' => $self->{'tags'},
	);

	return $self;
}

# Process 'Tags'.
sub _process {
	my ($self, $select) = @_;

	# Check input.
	if (! defined $select
		|| ! blessed($select)
		|| ! $select->isa('Data::HTML::Form::Select')) {

		err "Select object must be a 'Data::HTML::Form::Select' instance.";
	}

	$self->{'tags'}->put(
		['b', 'select'],
		defined $select->css_class ? (
			['a', 'class', $select->css_class],
		) : (),
		defined $select->id ? (
			['a', 'name', $select->id],
			['a', 'id', $select->id],
		) : (),
		defined $select->size ? (
			['a', 'size', $select->size],
		) : (),
		$select->disabled ? (
			['a', 'disabled', 'disabled'],
		) : (),
		# TODO Other. https://www.w3schools.com/tags/tag_select.asp
	);
	foreach my $option (@{$select->options}) {
		$self->{'_option'}->process($option);
	}
	$self->{'tags'}->put(
		['e', 'select'],
	);

	return;
}

sub _process_css {
	my ($self, $select) = @_;

	# Check select.
	if (! defined $select
		|| ! blessed($select)
		|| ! $select->isa('Data::HTML::Form::Select')) {

		err "Select object must be a 'Data::HTML::Form::Select' instance.";
	}

	my $css_class = '';
	if (defined $select->css_class) {
		$css_class = '.'.$select->css_class;
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
	if (@{$select->options}) {
		$self->{'_option'}->process_css($select->options->[0]);
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Form::Select - Tags helper for form select element.

=head1 SYNOPSIS

 use Tags::HTML::Form::Select;

 my $obj = Tags::HTML::Form::Select->new(%params);
 $obj->process($select);
 $obj->process_css($select);

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Form::Select->new(%params);

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

Accepted C<$select> is L<Data::HTML::Form::Select>.

Returns undef.

=head2 C<process_css>

 $obj->process_css($select);

Process CSS::Struct structure for C<$select> data object to output.

Accepted C<$select> is L<Data::HTML::Form::Select>.

Returns undef.

=head1 ERRORS

 new():
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Input object must be a 'Data::HTML::Form::Select' instance.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.
         Input object must be a 'Data::HTML::Form::Select' instance.

=head1 EXAMPLE

=for comment filename=create_and_print_select.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Form::Select;
 use Tags::HTML::Form::Select;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Form::Select->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for select.
 my $select = Data::HTML::Form::Select->new(
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
L<Tags::HTML::Form::Select::Option>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Form>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
