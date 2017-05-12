#!perl
use strict;
use warnings;

# PURPOSE:
# sequences of text..(blank|text)+..text should be collapsed into text
# sequences of data..(blank|data)+..data should be collapsed into data

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

is(@children, 4, "four top-level elements");

isa_ok($children[0], _pod5('Ordinary'), "...first element");
isa_ok($children[1], _pod5('Ordinary'), "...second element");
isa_ok($children[2], _pod5('Region'),   "...third element");
isa_ok($children[3], _pod5('Ordinary'), "...fourth element");

{
  # first region contents
  my @children = grep { ! $_->isa('Pod::Elemental::Element::Generic::Blank') }
                 @{ $children[2]->children };

  is(@children, 7, "top-level-contained region has five non-blanks");

  isa_ok($children[0], _pod5('Ordinary'), "...1st second-level para");
  isa_ok($children[1], _pod5('Ordinary'), "...2nd second-level para");
  isa_ok($children[2], _pod5('Verbatim'), "...3rd second-level para");
  isa_ok($children[3], _pod5('Ordinary'), "...4th second-level para");
  isa_ok($children[4], _pod5('Verbatim'), "...5th second-level para");
  isa_ok($children[5], _pod5('Region'),   "...6th second-level para");
  isa_ok($children[6], _pod5('Ordinary'), "...7th second-level para");

  {
    # second region contents
    my @children = grep { ! $_->isa('Pod::Elemental::Element::Generic::Blank') }
                   @{ $children[5]->children };

    is(@children, 1, "second-level-contained region has one non-blank");

    isa_ok($children[0], _pod5('Data'), "...1st third-level para");
  }
}

done_testing;

__DATA__
=pod

Ordinary Paragraph 1.1

Ordinary Paragraph 1.2

=begin :pod_like

Ordinary Paragraph 2.1

Ordinary Paragraph 2.2

  Verbatim Paragraph 2.1

  Verbatim Paragraph 2.2

Ordinary Paragraph 2.3

  Verbatim Paragraph 2.3

=begin nonpod

Data Paragraph 3.1

  Data Paragraph 3.2

Data Paragraph 3.3

=end nonpod

Ordinary Paragraph 2.4

=end :pod_like

Ordinary Paragraph 1.3

