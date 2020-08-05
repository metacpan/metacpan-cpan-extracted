package Mojo::DOM::Role::Analyzer ;
$Mojo::DOM::Role::Analyzer::VERSION = '0.008';
use strict;
use warnings;
use Role::Tiny;
use Devel::Confess;
use Carp;

use overload "cmp" => sub { $_[0]->compare(@_) }, fallback => 1;

sub element_count {
  my $self = shift;
  return $self->descendant_nodes->grep(sub { $_->type eq 'tag' })->size;
}

sub parent_all {
  my $self = shift;
  my $tag = shift || $self->tag;
  carp 'Unable to determine tag' if !$tag;
  my $p_count = $self->root->find($tag)->size;

  my $enclosing_tag = $self->root->at($tag);
  my $current_p_count = 0;
  while ($current_p_count < $p_count) {
    my $parent = $enclosing_tag->parent;
    $current_p_count = $parent->find('p')->size;
    $enclosing_tag = $parent;
  }
  return $enclosing_tag;
}

sub parent_ptags {
  my $self = shift;
  return $self->parent_all('p');
}

# determine if a tag A comes before or after tag B in the dom
sub compare {
  my ($sel1, $sel2);
  if (!$_[2]) {
    my $s = shift;
    $sel1 = $s->selector;
    $sel2 = $s->root->at($_[0])->selector;
  } else {
    $sel1 = $_[1]->selector;
    $sel2 = $_[2]->selector;
  }

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  foreach my $p1 (@t1_path) {
    my $p2 = shift(@t2_path);
    next if $p1 eq $p2;
    my ($p1_tag, $p1_num) = split /:/, $p1;
    my ($p2_tag, $p2_num) = split /:/, $p2;

    next if $p1_num eq $p2_num;
    return $p1_num cmp $p2_num;
  }
}

sub depth {
  my $s = shift;
  my $sel = $s->selector;
  my @parts = split /\s>\s/, $sel;
  return scalar @parts;
}

sub deepest {
  my $s = shift;
  my $deepest_depth = 0;
  foreach my $c ($s->descendant_nodes->grep(sub { $_->type eq 'tag' })->each) {
    my $depth = $c->depth;
    $deepest_depth = $depth if $depth > $deepest_depth;
  }
  return $deepest_depth;
}


1; # Magic true value
# ABSTRACT: miscellaneous methods for analyzing a DOM

__END__

=pod

=head1 NAME

Mojo::DOM::Role::Analyzer - miscellaneous methods for analyzing a DOM

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Mojo::Dom;

  my $html = '<html><head></head><body><p class="first">A paragraph.</p><p class="last">boo<a>blah<span>kdj</span></a></p><h1>hi</h1></body></html>';
  my $analyzer = Mojo::DOM->with_roles('+Analyzer')->new($html);

  # return the count of elements inside a dom objec
  my $count = $analyzer->at('body')->element_count;

  # get the smallest containing dom object that contains all the paragraph tags
  my $containing_dom = $analyzer->parent_ptags;

  # compare DOM objects to see which comes first in the document
  my $tag1 = $analyzer->at('p.first');
  my $tag2 = $analyzer->at('p.last');
  my $result = $analyzer->compare($tag1, $tag2);

  # ALTERNATIVELY

  $analyzer->at('p.first')->compare('p.last');    # 'p.last' is relative to root

  # get the depth level of a dom object relative to root
  # root node returns '1'
  my $depth = $analyzer->at('p.first')->depth;

  # get the deepest depth of the documented
  my $deepest = $analyzer->deepest;

=head1 DESCRIPTION

=head3 Operators

=head3 cmp

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to determine which comes first in
the dom. See C<compare> method below for return values.

=head2 Methods

=head3 element_count

  $count = $dom->element_count;

Returns the number of elements in a dom object, including children of children
of children, etc.

=head3 parent_all

  $dom = $dom->parent_all('a');                     # finds parent within root that contains all 'a' tags
  $dom = $dom->at('div.article')->parent_all('ul'); # finds parent within C<div.article> that has all 'ul' tags

Returns the smallest containing $dom within the $dom the method is called on
that wraps all the tags indicated in the argument.

=head3 parent_ptags

  $dom = $dom->parent_ptags;
  $dom = $dom->at('div.article')->parent_ptags;

A conveniece method that works like the C<parent_all> method but automatically supplies a
C<'p'> tag argument for you.

=head3 compare($dom1, $dom2)

  my $dom1 = $dom->at('p.first');
  my $dom2 = $dom->at('p.last');
  my $result = $dom->compare($dom1, $dom2);

  # OR with overloaded 'cmp' operator

  my $result = $dom1 cmp $dom2;

  # OR

  $dom->at('p.first')->compare('p.last');    # 'p.last' is relative to root

Compares the selectors of two $dom objects to see which comes first in the DOM.

=over 1

=item Returns a value of '-1' if the first argument comes before (is less than) the second.

=item Returns a value of '0' if the first and second arguments are the same.

=item Returns a value of '1' if the first argument comes after (is greater than) the second.

=back

=head3 depth

  my $depth = $dom->at('p.first')->depth;

Finds the nested depth level of a node. The root node returns 1.

=head3 deepest

  my $deepest_depth = $dom->deepest;

Finds the deeepest nested level within a node.

=head1 VERSION

version 0.008

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Mojo::DOM::Role::Analyzer

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Mojo-DOM-Role-Analyzer>

=back

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/Mojo-DOM-Role-Analyzer>

  git clone git://github.com/sdondley/Mojo-DOM-Role-Analyzer.git

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
