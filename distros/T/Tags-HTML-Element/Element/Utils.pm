package Tags::HTML::Element::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(tags_boolean tags_data tags_label tags_value);

our $VERSION = 0.08;

sub tags_boolean {
	my ($self, $element, $method) = @_;

	if ($element->$method) {
		return (['a', $method, $method]);
	}

	return ();
}

sub tags_data {
	my ($self, $object) = @_;

	# Plain content.
	if ($object->data_type eq 'plain') {
		$self->{'tags'}->put(
			map { (['d', $_]) } @{$object->data},
		);

	# Tags content.
	} elsif ($object->data_type eq 'tags') {
		$self->{'tags'}->put(@{$object->data});

	# Callback.
	} else {
		foreach my $cb (@{$object->data}) {
			$cb->($self);
		}
	}

	return;
}

sub tags_label {
	my ($self, $object) = @_;

	# CSS for required span.
	my $css_required = '';
	if (defined $object->css_class) {
		$css_required .= $object->css_class.'-';
	}
	$css_required .= 'required';

	$self->{'tags'}->put(
		defined $object->label ? (
			['b', 'label'],
			$object->id ? (
				['a', 'for', $object->id],
			) : (),
			['d', $object->label],
			$object->required ? (
				['b', 'span'],
				['a', 'class', $css_required],
				['d', '*'],
				['e', 'span'],
			) : (),
			['e', 'label'],
		) : (),
	);

	return;
}

sub tags_value {
	my ($self, $element, $method, $method_rewrite) = @_;

	if (defined $element->$method) {
		return ([
			'a',
			defined $method_rewrite ? $method_rewrite : $method,
			$element->$method,
		]);
	}

	return ();
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Element::Utils - Tags::HTML::Element utilities.

=head1 SYNOPSIS

 use Tags::HTML::Element::Utils qw(tags_boolean tags_data tags_label tags_value);

 tags_boolean($self, $element, $method);
 tags_data($self, $object);
 tags_label($self, $object);
 tags_value($self, $element, $method, $method_rewrite);

=head1 DESCRIPTION

Utilities for L<Tags::HTML::Element> classes.

=head1 SUBROUTINES

=head2 C<tags_boolean>

 tags_boolean($self, $element, $method);

Get L<Tags> structure for element attribute, which is boolean if C<$method>
exists.

Returns array of L<Tags> structure.

=head2 C<tags_data>

 tags_data($self, $object);

Get or process C<$object-E<gt>data> defined by C<$object-E<gt>data_type>
method.

Possible C<data_type> values are:

=over

=item plain

Convert plain text data in C<$object-E<gt>data> to L<Tags> data structure and
put to C<$self-E<gt>{'tags'}> method.

=item tags

Put L<Tags> data structure in C<$object-E<gt>data> and put to C<$self-E<gt>{'tags'}>
method.

=item cb

Call C<$object-E<gt>data> callback.

=back

=head2 C<tags_label>

 tags_label($self, $object);

Process L<Tags> structure for element label, which is before form item element.

Returns undef.

=head2 C<tags_value>

 tags_value($self, $element, $method, $method_rewrite);

Get L<Tags> structure for element attribute, which is value if C<$method>
exists. C<$method_rewrite> is value for key of attribute, when it's different
than C<$method> name.

Returns array of L<Tags> structure.

=head1 EXAMPLE1

=for comment filename=tags_boolean.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Tags::HTML::Element::Utils qw(tags_boolean);
 use Test::MockObject;

 my $self = {};
 my $obj = Test::MockObject->new;
 $obj->set_true('foo');

 # Process $obj->foo.
 my @tags = tags_boolean($self, $obj, 'foo');

 # Print out.
 p $tags[0];

 # Output (like attribute <element foo="foo">):
 # [
 #     [0] "a",
 #     [1] "foo",
 #     [2] "foo"
 # ]

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

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
