package Mojo::DOM::Role::Analyzer ;
$Mojo::DOM::Role::Analyzer::VERSION = '0.009';
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
  my $tag = shift;
  carp 'Unable to determine tag' unless $tag;
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

sub _get_selectors {
  my ($s, $sel1, $sel2);
  if (!$_[2]) {
    $s = shift;
    $sel1 = $s->selector;
    if (ref $_[0]) {
      $sel2 = $_[0]->selector;
    } else {
      $sel2 = $s->root->at($_[0])->selector;
    }
  } else {
    $s = $_[0];
    $sel1 = $_[1]->selector;
    $sel2 = $_[2]->selector;
  }
  return ($s, $sel1, $sel2);
}

# traverses the DOM upward to find the closest tag node
sub closest_up {
  return _closest(@_, 'up');
}

sub closest_down {
  return _closest(@_, 'down');
}

sub _closest {
  my $s = shift;
  my $sel = $s->selector;
  use Log::Log4perl::Shortcuts qw(:all);
  my $tag = shift;
  my $dir = shift || 'up';
  if ($dir ne 'up') {
    $dir = 'down';
  }

  my $found;
  if ($dir eq 'up') {
    $found = $s->root->find($tag)->grep(sub { ($s cmp $_) > 0  } );
  } else {
    $found = $s->root->find($tag)->grep(sub { ($s cmp $_) < 0  } );
  }

  return 0 unless $found->size;

  my $shortest_dist;
  my @shortest_selectors;
  foreach my $f ($found->each) {
    my $key = $f->selector;
    my $dist = $s->root->at($sel)->distance($f);
    if (!$shortest_dist) {
      $shortest_dist = $dist;
      push @shortest_selectors, $key;
    } elsif ($dist <= $shortest_dist) {
      if ($dist < $shortest_dist) {
        @shortest_selectors = ();
        push @shortest_selectors, $key;
      } else {
        $shortest_dist = $dist;
        push @shortest_selectors, $key;
      }
    }
  }

  if (@shortest_selectors == 1) {
    return $s->root->at($shortest_selectors[0]);
  }

  my @sorted = sort { $s->root->at($a) cmp $s->root->at($b) } @shortest_selectors;
  if ($dir eq 'up') {
    return $s->root->at($sorted[-1]);  # get furthers from the top (closest to node of interest)
  } else {
    return $s->root->at($sorted[0]);   # get futherst from the bottom (closest to node of interest)
  }

}

# determine if a tag A comes before or after tag B in the dom
sub compare {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

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

sub distance {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

  my $common = common($s, $s->root->at($sel1), $s->root->at($sel2));
  my $dist_leg1 = $s->root->at($sel1)->depth - $common->depth;
  my $dist_leg2 = $s->root->at($sel2)->depth - $common->depth;

  return $dist_leg1 + $dist_leg2;
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

# find the common ancestor between two nodes
sub common {
  my ($s, $sel1, $sel2);
  if ($_[1] && $_[2] && !ref $_[1] && !ref $_[2]) {
    ($s, $sel1, $sel2) = @_;
  } else {
    ($s, $sel1, $sel2) = _get_selectors(@_);
  }

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  my @last_common;
  foreach my $p1 (@t1_path) {
    my $p2 = shift(@t2_path);
    if ($p1 eq $p2) {
      push @last_common, $p1;
    } else {
      last;
    }
  }
  my $common_selector = join ' > ', @last_common;

  return $s->root->at($common_selector);

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

=head2 Operators

=head3 cmp

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to determine which comes first in
the dom. See C<compare> method below for return values.

=head2 Methods

=head3 closest_up

  my $closest_up_dom = $dom->at('p')->closest_up('h1');

Returns the node closest to the tag node of interest by searching upward through the DOM.

=head4 closest_down

  my $closest_down_dom = $dom->at('h1')->closest_down('p');

Returns the node closest to the tag node of interest by searching downward through the DOM.

=head3 closest_down

=head3 distance

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($selector)>

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($dom)>

=head4 C<$dom-E<gt>distance($dom1, $dom2)>

Finds the distance between two nodes. The value is calculated by finding the
lowest common ancestor node for the two nodes and then adding the distance from
each individual node to the lowest common ancestor node.

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

=head3 common

=head4 C<$dom-E<gt>at($tag1)-E<gt>common($tag2)>

=head4 C<$dom-E<gt>common($dom1, $dom2)>

=head4 C<$dom-E<gt>common($selector_str1, $selector_str2)>

  my $common_dom = $dom->at('div.bar')->common('div.foo');    # 'div.foo' is relative to root

  # OR

  my $dom1 = $dom->at('div.bar');
  my $dom2 = $dom->at('div.foo');
  my $common = $dom->common($dom1, $dom2);

  # OR

  my $common = $dom->common($dom->at('p')->selector, $dom->at('h1')->selector);

Returns the lowest common ancestor node between two tag nodes or two selector strings.

=head3 compare

=head4 C<$dom-E<gt>at($tag1)-E<gt>compare($tag2)>

=head4 C<compare($dom1, $dom2)>

=head4 C<$dom1 cmp $dom2>

  $dom->at('p.first')->compare('p.last');    # 'p.last' is relative to root

  # OR

  my $dom1 = $dom->at('p.first');
  my $dom2 = $dom->at('p.last');
  my $result = $dom->compare($dom1, $dom2);

  # OR with overloaded 'cmp' operator

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to see which comes first in the DOM.

=over 1

=item * Returns a value of '-1' if the first argument comes before (is less than) the second.

=item * Returns a value of '0' if the first and second arguments are the same.

=item * Returns a value of '1' if the first argument comes after (is greater than) the second.

=back

=head3 depth

  my $depth = $dom->at('p.first')->depth;

Finds the nested depth level of a node. The root node returns 1.

=head3 deepest

  my $deepest_depth = $dom->deepest;

Finds the deeepest nested level within a node.

=head1 VERSION

version 0.009

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
