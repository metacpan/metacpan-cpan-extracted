package Tags::HTML::Element::A;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.02;

sub _cleanup {
	my $self = shift;

	delete $self->{'_a'};

	return;
}

sub _init {
	my ($self, $a) = @_;

	# Check a.
	if (! defined $a
		|| ! blessed($a)
		|| ! $a->isa('Data::HTML::Element::A')) {

		err "Input object must be a 'Data::HTML::Element::A' instance.";
	}

	$self->{'_a'} = $a;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_a'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'a'],
		$self->_tags_value($self->{'_a'}, 'css_class', 'class'),
		$self->_tags_value($self->{'_a'}, 'url', 'href'),
	);
	if ($self->{'_a'}->data_type eq 'plain') {
		$self->{'tags'}->put(
			['d', @{$self->{'_a'}->data}],
		);
	} elsif ($self->{'_a'}->data_type eq 'tags') {
		$self->{'tags'}->put(@{$self->{'_a'}->data});
	}
	$self->{'tags'}->put(
		['e', 'a'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	return;
}

sub _tags_value {
	my ($self, $object, $method, $method_rewrite) = @_;

	if (defined $object->$method) {
		return ([
			'a',
			defined $method_rewrite ? $method_rewrite : $method,
			$object->$method,
		]);
	}

	return ();
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::A - Tags helper for HTML a element.

=head1 SYNOPSIS

 use Tags::HTML::Element::A;

 my $obj = Tags::HTML::Element::A->new(%params);
 $obj->cleanup;
 $obj->init($a);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Element::A->new(%params);

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

In this case cleanup internal representation of a set by L<init>.

Returns undef.

=head2 C<init>

 $obj->init($a);

Process initialization in page run.

Accepted C<$a> is L<Data::HTML::Element::A>.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Do nothing in this object.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for HTML a element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for HTML a element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head1 ERRORS

 new():
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Input object must be a 'Data::HTML::Element::A' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=create_and_print_a.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::A;
 use Tags::HTML::Element::A;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Element::A->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for a.
 my $a = Data::HTML::Element::A->new(
         'css_class' => 'a',
         'data' => ['Link'],
         'url' => 'http://example.com',
 );

 # Initialize.
 $obj->init($a);

 # Process a.
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
 # <a class="a" href="http://example.com">
 #   Link
 # </a>
 #
 # CSS:
 # - no CSS now.

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

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
