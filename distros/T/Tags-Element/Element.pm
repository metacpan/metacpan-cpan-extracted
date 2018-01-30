package Tags::Element;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(element);

# Version.
our $VERSION = 0.03;

# Common element.
sub element {
	my ($element, @data) = @_;
	my @attr;
	my @content;
	foreach my $ref (@data) {
		if (ref $ref eq 'HASH') {
			foreach my $key (sort keys %{$ref}) {
				push @attr, ['a', $key, $ref->{$key}];
			}
		} elsif (ref $ref eq 'ARRAY') {
			push @content, @{$ref};
		} else {
			push @content, ['d', $ref];
		}
	}
	return (
		['b', $element],
		@attr ? @attr : (),
		@content ? @content : (),
		['e', $element],
	);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::Element - Element utilities for 'Tags'.

=head1 SYNOPSIS

 use Tags::Element qw(element);
 my @tags = element($element, @data);

=head1 SUBROUTINES

=over 8

=item C<element($element, @data)>

 Common element helper for writing Tags code.
 Returns array of element in Tags format.

=back

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Tags::Element qw(element);

 # Get example element.
 my @tags = element('div', {
         'id' => 'foo',
         'class' => 'bar',
 }, 'Foo', 'Bar');

 # Dump to stdout.
 p @tags;

 # Output.
 # [
 #     [0] [
 #         [0] "b",
 #         [1] "div"
 #     ],
 #     [1] [
 #         [0] "a",
 #         [1] "class",
 #         [2] "bar"
 #     ],
 #     [2] [
 #         [0] "a",
 #         [1] "id",
 #         [2] "foo"
 #     ],
 #     [3] [
 #         [0] "d",
 #         [1] "Foo"
 #     ],
 #     [4] [
 #         [0] "d",
 #         [1] "Bar"
 #     ],
 #     [5] [
 #         [0] "e",
 #         [1] "div"
 #     ]
 # ]

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Tags::Element qw(element);
 use Tags::Output::Raw;

 # Get example element.
 my @tags = element('div', {
         'id' => 'foo',
         'class' => 'bar',
 }, 'Foo', 'Bar');

 # Serialize by Tags.
 my $tags = Tags::Output::Raw->new;
 $tags->put(@tags);
 print $tags->flush."\n";

 # Output.
 # <div class="bar" id="foo">FooBar</div>

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Tags>

Structure oriented SGML/XML/HTML/etc. elements manipulation.

=item L<Task::Tags>

Install the Tags modules.

=back

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

 © 2011-2018 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
