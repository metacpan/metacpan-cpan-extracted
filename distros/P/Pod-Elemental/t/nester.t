#!perl
use strict;
use warnings;

use Test::More;
use Test::Differences;

use Pod::Eventual::Simple;
use Pod::Elemental;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

my $str = do { local $/; <DATA> };

my $document = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->transform_node($document);

my $nester = Pod::Elemental::Transformer::Nester->new({
  top_selector => s_command('head1'),
  content_selectors => [
    s_flat,
    s_command( [ qw(head2 head3 head4 over item back) ]),
  ],
});

$nester->transform_node($document);

my @children = @{ $document->children };

is(@children, 3, "the nested document has 3 top-level elements"); 

ok(s_flat($children[0]), "the first paragraph is a flat/text paragraph");

ok(
  $children[1]->isa('Pod::Elemental::Element::Nested'),
  "the second paragraph is a nested command node",
);

{
  my @children = @{ $children[1]->children };
  is(@children, 7, "...which has 7 children");
}

ok(
  $children[2]->isa('Pod::Elemental::Element::Nested'),
  "the third paragraph is a nested command node",
);

{
  my @children = @{ $children[2]->children };
  is(@children, 1, "...which has 1 child");
}

eq_or_diff($document->as_pod_string, $str, "round-tripped okay");

done_testing;

__DATA__
=pod

Ordinary Paragraph 1.1

=head1 Header 1.1

=head2 Header 2.1

=head2 Header 2.2

Ordinary Paragraph 2.1

=head3 Header 3.1

=over 4

=item * foo

=back

=head1 Header 1.2

Ordinary Paragraph 2.1

=cut
