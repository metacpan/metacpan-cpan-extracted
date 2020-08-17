package Mojo::DOM::Role::Analyzer ;
$Mojo::DOM::Role::Analyzer::VERSION = '0.015';
use strict;
use warnings;
use Role::Tiny;
use Carp;
#use Log::Log4perl::Shortcuts qw(:all);


use overload "cmp" => sub { $_[0]->compare(@_) }, fallback => 1;

# wrap the find method so we can call the common method on collections
around find => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig(@_)->with_roles('+Extra');
};

# traverses the DOM upward to find the closest tag node
sub closest_up {
  return _closest(@_, 'up');
}

# traverses the DOM downward to find the closest tag node
sub closest_down {
  return _closest(@_, 'down');
}

sub _closest {
  my $s = shift;
  my $sel = $s->selector;
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

  my @selectors;
  foreach my $f ($found->each) {
    push @selectors, $f->selector;
  }

  if (@selectors == 1) {
    return $s->root->at($selectors[0]);
  }

  my @sorted = sort { $s->root->at($a) cmp $s->root->at($b) } @selectors;
  if ($dir eq 'up') {
    return $s->root->at($sorted[-1]);  # get furtherest from the top (closest to node of interest)
  } else {
    return $s->root->at($sorted[0]);   # get futherest from the bottom (closest to node of interest)
  }

}

# find the common ancestor between a node and another node or group of nodes
sub common {
# uncomment to debug
# use Log::Log4perl::Shortcuts qw(:all); # for development only
#  if (ref $_[0]) { logd ref $_[0]; } else { logd $_[0]; }
#  if (ref $_[1]) { logd ref $_[1]; } else { logd $_[1]; }
#  if (ref $_[2]) { logd ref $_[2]; } else { logd $_[2]; }

   # The argument handling is a bit confusing. Keep these important notes in mind while reading this code:

   # 1) This method is called on Mojo::DOM objects (obviously)
   # 2) Don't confuse this method with its sister method also named "common"
   #    in Mojo::DOM::Collection::Extra which works with Mojo::Collection objects
   # 3) The argument handling below works for the different types of common syntaxes noted
   #    below in the comments.

  my ($s, $sel1, $sel2);

  # function-like use of common: $dom->commont($dom1, $dom2)
  if (ref $_[1] && ref $_[2]) {
    $s = $_[0];
    $sel1 = $_[1]->selector;
    $sel2 = $_[2]->selector;
  # DWIM syntax handling
  } else {
    if (!$_[1] && !$_[2]) {                         # $dom->at('div');
      my $s = shift;
      return $s->root->find($s->selector)->common;
    } elsif ($_[1] && !ref $_[1] && !$_[2]) {       # $dom->at('div.first')->common('p');
      $s = shift;
      $sel1 = $s->selector;
      $sel2 = $s->root->at(shift)->selector;
    }
  }

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  my @common_path;
  foreach my $seg (@t1_path) {
    my $seg2 = shift @t2_path;
    last if !$seg2 || $seg ne $seg2;
    push @common_path, $seg2;
  }

  my $common_selector = join ' > ', @common_path;

  return $s->root->at($common_selector);

}

# determine if a tag A comes before or after tag B in the dom
sub compare {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

  my @t1_path = split / > /, $sel1;
  my @t2_path = split / > /, $sel2;

  my $t1_len = scalar @t1_path;
  my $t2_len = scalar @t2_path;

  my $equal = 0;
  foreach my $p1 (@t1_path) {
    $equal = 0;
    my $p2 = shift(@t2_path);
    last if !$p2;
    if ($p1 eq $p2) {
      $equal = 1;
      next;
    }
    my ($p1_num) = $p1 =~ /child\((\d+)\)/;
    my ($p2_num) = $p2 =~ /child\((\d+)\)/;

    return ($p1_num <=> $p2_num);
  }
  return 0 if $t1_len == $t2_len;
  return $t1_len < $t2_len ? -1 : 1;
}

sub distance {
  my ($s, $sel1, $sel2) = _get_selectors(@_);

  my $common = $s->common($s->root->at($sel1), $s->root->at($sel2));
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

sub element_count {
  my $self = shift;
  return $self->descendant_nodes->grep(sub { $_->type eq 'tag' })->size;
}

# determine if one node is an ancestor to another
sub is_ancestor_to {
  my $s = shift;
  my $arg = shift;
  my $sel1 = $s->selector;
  my $sel2 = $arg->selector;

  return $sel2 =~ /^\Q$sel1\E/ ? 1 : 0;
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

sub tag_analysis {
  my $s        = shift;
  my $selector = shift;

  carp "A selector argument must be passed to the tag_analysis method"
    unless $selector;

  my $ec = $s->find($selector)->common;
  my @sub_enclosing_nodes = $ec->_gsec($selector, 1);

  foreach my $sn (@sub_enclosing_nodes) {
    next if $sn->{all_tags_have_same_depth} || $sn->{top_level};
    my $n = $s->at($sn->{selector});
    my @enclosing_nodes = $n->_gsec($selector);
    push @sub_enclosing_nodes, @enclosing_nodes;
  }

  # cleanup
  @sub_enclosing_nodes = sort { $a->{selector} cmp $b->{selector} } @sub_enclosing_nodes;
  my $last_node;
  my @filtered_enclosing_nodes;
  foreach my $sen (@sub_enclosing_nodes) {
    if (!$last_node) {
      $last_node = $sen;
      next;
    }

    if ($s->at($last_node->{selector})->is_ancestor_to($s->at($sen->{selector}))) {
      if ($last_node->{size} != $sen->{size} || $last_node->{direct_children} != $sen->{direct_children}) {
        push @filtered_enclosing_nodes, $last_node;
      }
    } else {
      push @filtered_enclosing_nodes, $last_node;
    }
    $last_node = $sen;
  }
  push @filtered_enclosing_nodes, $last_node;

  return @filtered_enclosing_nodes;

}

# get secondary enclosing tags
sub _gsec {
  my $s = shift;
  my $selector = shift;
  my $top_level = shift;
  my %props;

  my @sub_enclosing_nodes;

  if ($top_level) {
    $props{top_level} = 1;
    $props{selector} = $s->selector;
    $props{size} = $s->find($selector)->size;
    my ($depth_total, $same_depth, $classes) = $s->_calc_depth($selector);

    $props{classes} = $classes;
    $props{direct_children} = $s->children($selector)->size;;
    my $avg_depth = sprintf('%.3f', ($depth_total / $props{size}));
    $avg_depth =~ s/\.0+$//g;
    $props{avg_tag_depth} = $avg_depth;
    $props{all_tags_have_same_depth} = $same_depth;
    push @sub_enclosing_nodes, \%props;
  }

  foreach my $c ($s->children->each) {
    next if $c->tag eq $selector;
    my $size = $c->find($selector)->size;
    next unless $size;

    my $cdn_with_sel = $c->children($selector)->size;
    my ($depth_total, $same_depth, $classes) = $c->_calc_depth($selector);

    my $avg_depth = sprintf('%.3f', ($depth_total / $size));
    $avg_depth =~ s/\.0+$//g;
    push @sub_enclosing_nodes,  { selector => $c->selector,
                                  size => $size,
                                  classes => $classes,
                                  avg_tag_depth => $avg_depth,
                                  all_tags_have_same_depth => $same_depth,
                                  direct_children => $cdn_with_sel,
                                };
  }

  return @sub_enclosing_nodes;

}

sub _calc_depth {
  my $s = shift;
  my $selector = shift;
  my $depth_total;
  my $same_depth    = 1;
  my $depth_tracker = undef;

  my %classes;
  foreach my $t ($s->find($selector)->each) {
    if ($t->attr('class')) {
      my @classes = split ' ', $t->attr('class');
      $classes{$t->attr('class')}++;

#      my @classes = split ' ', $t->attr('class');
#      foreach my $cl (@classes) {
#        $classes{$cl}++;
#      }
    }
    my $depth = $t->depth;

    if ($depth_tracker && ($depth != $depth_tracker)) {
      $same_depth = 0;
    }

    $depth_tracker = $depth;
    $depth_total  += $depth;
  }

  return ($depth_total, $same_depth, \%classes);
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
  use Mojo::DOM;

  my $html = '<html><head></head><body><p class="first">A paragraph.</p><p class="last">boo<a>blah<span>kdj</span></a></p><h1>hi</h1></body></html>';
  my $analyzer = Mojo::DOM->with_roles('+Analyzer')->new($html);

  # return the number of elements inside a dom object
  my $count = $analyzer->at('body')->element_count;

  # get the smallest containing dom object that contains all the paragraph tags
  my $containing_dom = $analyzer->common_ancestor('p');

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

  # SEE DESCRIPTION BELOW FOR MORE METHODS

=head1 DESCRIPTION

=head2 Operators

=head3 cmp

  my $result = $dom1 cmp $dom2;

Compares the selectors of two $dom objects to determine which comes first in
the dom. See C<compare> method below for return values.

=head2 Methods

=head3 closest_down

  my $closest_down_dom = $dom->at('h1')->closest_down('p');

Returns the node closest to the tag node of interest by searching downward
through the DOM.

Note that "closest" is defined as the node highest in the DOM that is still
below the tag node of interest (or, in the case of L<closeest_up> lowest in the
DOM but still above the tag node of interest), not by the shortest distance
(number of "hops") to the other node.

For example, in the code below, the C<E<lt>h1E<gt>> tag containing "Heading 1"
is five hops away from the C<E<lt>pE<gt>> tag, while the other
C<E<lt>h1E<gt>> tag is only two hops away. But despite being more hops away,
the C<E<lt>h1E<gt>> tag containing "Header 1" is considered to be closer.

    <p>Paragraph</p>
    <div><div><div><div><h1>Heading 1</h1></div></div></div></div>
    <h1>Heading 2</h2>

=head3 closest_up

  my $closest_up_dom = $dom->at('p')->closest_up('h1');

Returns the node closest to the tag node of interest by searching upward
through the DOM.

See the L<closest_down> method for the meaning of the "closest" node and how it
is calculated.

=head3 common

=head4 C<$dom-E<gt>at($tag1)-E<gt>common($tag2)>

=head4 C<$dom-E<gt>common($dom1, $dom2)>

=head4 C<$dom-E<gt>common($selector_str1, $selector_str2)>

=head4 C<$dom-E<gt>at($tag1)-E<gt>common>

  # Find the common ancestor for two nodes
  my $common $dom->at('div.bar')->common('div.foo');    # 'div.foo' is relative to root

  # OR

  # Pass in two $dom objects
  my $dom1 = $dom->at('div.bar');
  my $dom2 = $dom->at('div.foo');
  my $common = $dom->common($dom1, $dom2);

  # OR

  # Pass in two selectors
  my $common = $dom->common($dom->at('p')->selector, $dom->at('h1')->selector);

  # OR

  # Find the common ancestor for all paragraph nodes with class "foo"
  # This syntax is a wrapper for the Mojo::Collection::Role::Extra->common method
  my $common = $dom->at('p.foo')->common;

Returns the lowest common ancestor node between two nodes or
between a node and a group of nodes sharing the same selector.

See L<Mojo::Collection::Role::Extra/common> for a similar method that invoked
on Mojo::Collection objects.

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

=head3 deepest

  my $deepest_depth = $dom->deepest;

Finds the deeepest nested level within a node.

=head3 depth

  my $depth = $dom->at('p.first')->depth;

Finds the nested depth level of a node. The root node returns 1.

=head3 distance

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($selector)>

=head4 C<$dom-E<gt>at($selector)-E<gt>distance($dom)>

=head4 C<$dom-E<gt>distance($dom1, $dom2)>

Returns the distance, aka number of "hops," between two nodes.

The value is calculated by first finding the lowest common ancestor node for
the two nodes and then getting the distance between the lowest common ancestor
node and each of the two nodes. The two distances are then added togethr to
determine the total distance between the two nodes.

=head3 element_count

  $count = $dom->element_count;

Returns the number of elements in a dom object, including children of children
of children, etc.

=head3 is_ancestor_to

  $is_ancestor = $s->at('h1')->is_ancestor_to('p.foo');

Returns true if a node is an ancestor to another node, false otherwise.

=head3 tag_analysis

  @enclosing_tags = $dom->tag_analysis('p');

Searches through a DOM for tag nodes that enclose tags matching the given
selector (see L<common_ancestor> method) and returns an array of hash references
with the following information for each of the enclosing nodes:

  {
    "all_tags_have_same_depth" => 1,   # whether enclosed tags within the enclosing node have the same depth
    "avg_tag_depth" => 8,              # average depth of the enclosed tags
    "selector" => "body:nth-child(2)", # the selector for the enclosing tag
    "size" => 1                        # total number of tags of interest that are descendants of the enclosing tag
  }

=head1 VERSION

version 0.015

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

=head1 SEE ALSO

L<Mojo::DOM>
L<Mojo::Collection::Role::Extra>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
