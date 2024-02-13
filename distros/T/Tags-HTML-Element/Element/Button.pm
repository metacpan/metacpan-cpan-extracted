package Tags::HTML::Element::Button;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);
use Tags::HTML::Element::Utils qw(tags_boolean tags_data tags_value);

our $VERSION = 0.08;

sub _cleanup {
	my $self = shift;

	delete $self->{'_button'};

	return;
}

sub _init {
	my ($self, $button) = @_;

	# Check button.
	if (! defined $button
		|| ! blessed($button)
		|| ! $button->isa('Data::HTML::Element::Button')) {

		err "Input object must be a 'Data::HTML::Element::Button' instance.";
	}

	$self->{'_button'} = $button;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_button'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'button'],
		['a', 'type', $self->{'_button'}->type],
		tags_value($self, $self->{'_button'}, 'css_class', 'class'),
		tags_value($self, $self->{'_button'}, 'name'),
		tags_value($self, $self->{'_button'}, 'id'),
		tags_value($self, $self->{'_button'}, 'value'),
		tags_boolean($self, $self->{'_button'}, 'autofocus'),
		tags_boolean($self, $self->{'_button'}, 'disabled'),
	);
	tags_data($self, $self->{'_button'});
	$self->{'tags'}->put(
		['e', 'button'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_button'}) {
		return;
	}

	my $css_class = '';
	if (defined $self->{'_button'}->css_class) {
		$css_class = '.'.$self->{'_button'}->css_class;
	}

	$self->{'css'}->put(
		['s', 'button'.$css_class],
		['d', 'width', '100%'],
		['d', 'background-color', '#4CAF50'],
		['d', 'color', 'white'],
		['d', 'padding', '14px 20px'],
		['d', 'margin', '8px 0'],
		['d', 'border', 'none'],
		['d', 'border-radius', '4px'],
		['d', 'cursor', 'pointer'],
		['e'],

		['s', "button$css_class:hover"],
		['d', 'background-color', '#45a049'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Button - Tags helper for HTML button element.

=head1 SYNOPSIS

 use Tags::HTML::Element::Button;

 my $obj = Tags::HTML::Element::Button->new(%params);
 $obj->cleanup;
 $obj->init($button);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::Button->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

In this case cleanup internal representation of button set by L<init>.

Returns undef.

=head2 C<init>

 $obj->init($button);

Process initialization in page run.

Accepted C<$button> is L<Data::HTML::Element::Button>.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Do nothing in this object.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for HTML button element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for HTML button element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head1 ERRORS

 new():
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Input object must be a 'Data::HTML::Element::Button' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=create_and_print_button.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::Button;
 use Tags::HTML::Element::Button;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Element::Button->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for button.
 my $button = Data::HTML::Element::Button->new(
         'css_class' => 'button',
 );

 # Initialize.
 $obj->init($button);

 # Process button.
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
 # <button type="button" class="button" />
 #
 # CSS:
 # button.button {
 #         width: 100%;
 #         background-color: #4CAF50;
 #         color: white;
 #         padding: 14px 20px;
 #         margin: 8px 0;
 #         border: none;
 #         border-radius: 4px;
 #         cursor: pointer;
 # }
 # button.button:hover {
 #         background-color: #45a049;
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

0.08

=cut
