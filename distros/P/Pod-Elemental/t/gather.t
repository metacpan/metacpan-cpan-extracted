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
use Pod::Elemental::Transformer::Gatherer;

my $str = do { local $/; <DATA> };

my $document = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->transform_node($document);

my $nester = Pod::Elemental::Transformer::Nester->new({
  top_selector => s_command([ qw(head1 method) ]),
  content_selectors => [
    s_flat,
    s_command( [ qw(head2 head3 head4 over item back) ]),
  ],
});

my $gatherer = Pod::Elemental::Transformer::Gatherer->new({
  gather_selector => s_command([ qw(method) ]),
  container       => Pod::Elemental::Element::Nested->new({
    command => 'head1',
    content => "METHODS\n",
  }),
});

$nester->transform_node($document);
$gatherer->transform_node($document);

$_->command('head2')
  foreach grep { s_command('method')->($_) } @{ $gatherer->container->children };

my @children = @{ $document->children };

is(@children, 4, "the nested document has 4 top-level elements"); 

ok(s_flat($children[0]), "the first paragraph is a flat/text paragraph");

ok(
  $children[1]->isa('Pod::Elemental::Element::Nested'),
  "the second paragraph is a nested command node",
);

{
  my @children = @{ $children[1]->children };
  is(@children, 1, "...which has 1 child");
}

ok(
  $children[2]->isa('Pod::Elemental::Element::Nested'),
  "the third paragraph is a nested command node",
);

{
  my @children = @{ $children[2]->children };
  is(@children, 2, "...which has 2 children");

  {
    my @children = @{ $children[0]->children };
    is(@children, 10, "...the first of which which has 10 children");
  }
}

ok(
  $children[3]->isa('Pod::Elemental::Element::Nested'),
  "the fourth paragraph is a nested command node",
);

{
  my @children = @{ $children[3]->children };
  is(@children, 1, "...which has 1 child");
}

done_testing;

__DATA__
=pod

Ordinary Paragraph 1.1

=head1 Header 1.1

=head2 Header 2.1

=method foo

Ordinary Paragraph 2.1

=over 2

=item * bar

=back

=head2 Header 2.2

Ordinary Paragraph 2.2

=head3 Header 3.1

=over 4

=item * foo

=back

=head1 Header 1.2

Ordinary Paragraph 2.3

=method quux

Ordinary Paragraph 2.4

=cut
