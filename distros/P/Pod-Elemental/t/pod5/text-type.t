#!perl
use strict;
use warnings;

# PURPOSE:
# show that pod-like regions have Ordinary text paragraphs and non-pod-like
# regions have data paragraphs

use Test::More;
use Test::Differences;

use Pod::Eventual::Simple;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;

sub _pod5 { "Pod::Elemental::Element::Pod5::$_[0]" }

my $str = do { local $/; <DATA> };

my $document = Pod::Elemental::Transformer::Pod5->transform_node(
  Pod::Elemental->read_string($str),
);

my @children = grep { ! $_->isa('Pod::Elemental::Element::Generic::Blank') }
               @{ $document->children };

is(@children, 2, "two top-level elements");
isa_ok($children[0], _pod5('Ordinary'), "...first top-level text");
isa_ok($children[1], _pod5('Region'),   "...second top-level para");

{
  # region contents
  my @children = grep { ! $_->isa('Pod::Elemental::Element::Generic::Blank') }
                 @{ $children[1]->children };

  is(@children, 5, "top-level-contained region has five non-blanks");

  isa_ok($children[0], _pod5('Ordinary'), "...1st second-level para");
  isa_ok($children[1], _pod5('Verbatim'), "...2nd second-level para");
  isa_ok($children[2], _pod5('Ordinary'), "...3rd second-level para");
  isa_ok($children[3], _pod5('Region'),   "...4th second-level para");
  isa_ok($children[4], _pod5('Ordinary'), "...5th second-level para");
}

done_testing;

__DATA__
=pod

Ordinary Paragraph

=begin :pod_like

Ordinary Paragraph

  Verbatim Paragraph

Ordinary Paragraph

=begin nonpod

Data Paragraph

=end nonpod

Ordinary Paragraph

=end :pod_like

