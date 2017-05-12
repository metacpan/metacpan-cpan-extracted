
require 5;
 # Time-stamp: "2004-12-29 18:41:19 AST"

package Pod::HTML2Pod;
use strict;
use integer; # haul aaaaaaaaaass!
use UNIVERSAL ();
use Carp ();
use HTML::TreeBuilder 3.01 ();
use HTML::Element 3.05 ();
use HTML::Tagset (); # presumably used by HTML::TreeBuilder anyhow
use HTML::Entities (); # presumably used by HTML::Parser anyhow
use vars qw($Debug $VERSION %Phrasal %Char2ent
            $nbsp $E_slash $E_vbar $counter);

$VERSION = '4.05';
$Debug = 0 unless defined $Debug;

=head1 NAME

Pod::HTML2Pod -- translate HTML into POD

=head1 SYNOPSIS

  # Use the program 'html2pod' that comes in this dist, or:
  use Pod::HTML2Pod;
  print Pod::HTML2Pod::convert(
    'file' => 'my_stuff.html',  # input file
    'a_href' => 1,  # try converting links
  );

=head1 DESCRIPTION

Larry Wall once said (1999-08-27, on the C<pod-people> list, I
do believe): "The whole point of pod is to get people to document stuff
they wouldn't document in any other form."

To that end, I wrote this module so that people who are unpracticed
with POD but in a hurry to simply document their programs or modules,
could write their documentation in simple HTML, and convert that to
POD.  That's what this module does.

Specifically, this module bends over backwards to try to turn even
vaguely plausable HTML into POD -- and when in doubt, it simply ignores
things that it doesn't know about, or can't render.

=head1 FUNCTIONS

This module provides one documented function, which it does not export:

=over

=item Pod::HTML2Pod::convert( ...options... )

=back

This returns a single scalar value containing the converted POD text,
with some comments after the end.

This function takes options:

=over

=item 'file' => FILENAME,

Specifies that the HTML code is to be read from the filename given.

=item 'handle' => *HANDLE,

Specifies that the HTML code is to be read from the open filehandle
given (e.g., C<$fh_obj>, C<*HANDLE>, C<*HANDLE{IO}>, etc.)  If you
specify this, but fail to specify an actual handle object, inscrutible
errors may result.

=item 'content' => STRING,

Specifies that the HTML code is in the string given.  (Alternately,
pass a reference to the scalar: C<'content' =E<gt> \$stuff>.)

=item 'tree' => OBJ,

Specifies that the HTML document is contained in the given
HTML::TreeBuilder object (or HTML::Element object, at least).

=item 'a_name' => BOOLEAN,

Specifies whether you want to try converting C<E<lt>a name="..."E<gt>>
elements.  By default this is off -- i.e., such elements are ignored.

=item 'a_href' => BOOLEAN,

Specifies whether you want to try converting C<E<lt>a href="..."E<gt>>
elements.  By default this is off -- i.e., such elements are ignored.
If on, bear in mind that relative URLs cannot be properly converted to
POD -- any relative URLs will be complained about in comments after
the end of the document.  Normal absolute URLs will be treated as best
they can be.  Note that URLs beginning "pod:..." will be turned into
POD links to whatever follows; that is, "pod:Getopt::Std" is turned
into C<LE<lt>Getopt::StdE<gt>>

=item 'debug' => INTEGER,

Puts Pod::HTML2Pod into verbose debug mode for the duration of
processing this this HTML document.  INTEGER can be 0 for no debug
output, 1 for a moderate amount that will cause the HTML syntax tree
to be be dumped at the start of the conversion, and 2 for that plus a
dump of the intermediate POD doctree, plus a few more inscrutible
diagnostic messages.  Looking at the trees dumped might be helpful in
making sense of error messages that refer to a particular node in the
parse tree.

=item

=back

=head1 GUIDELINES

Don't write crappy HTML and expect this module to understand it.

Don't take the output of C<pod2html> and feed it to this, just because
you think it'd be neat to try it.  You'll just learn really unpleasant
things about C<Pod::Html> -- and that's fine if that means you'll use
it to improve C<Pod::Html>, but it's rather the long way around.

However, I<do> use this module to convert simple HTML into POD,
bearing in mind these simple truths:

POD can't do tables, images, forms, imagemaps, layers, CSS, embedded
Java applets or any other kind of object, FONT, or BLINK.  So don't
try to do any of these things.

Use C<E<lt>h1E<gt>> and C<E<lt>h2E<gt>> for headings.

If you want to have a block of literal example code, put it in a 
C<E<lt>preE<gt>>.

Keep things simple.

Remember: Just because it comes I<out> of Pod::HTML2Pod doesn't mean
it's happy normal pod.  You can do lots of things in HTML that will
produce POD that is strange but technically legal (like having huge
and complex content in a C<E<lt>h1E<gt>>/C<=head1>) but that will make
perldoc scream bloody murder about nroff macros stretched past their
limit.

Try to avoid using a WYSIWYG HTML editor, as they often produce scary
source.  Ditto for taking selecting "Save as... HTML" in your word
processor.  You can always try it, but look at the HTML to survey the
damage before you try converting it to POD.

Always look at the POD that's been output by HTML2Pod -- never just
blindly include it.

Consider starting from this template:

  <html>
  <head>
   <title>Things::Stuff</title>
   <!-- html2pod ignores everything outside the body anyway -->
  </head>
  <body>
  <h1>NAME</h1>
  
  Things::Stuff -- does some things with stuff
  
  <h1>SYNOPSIS</h1>
  <!-- example code -->
  <pre>
    use HTML::Stuff;
    do some more stuff;
    la la la la la;
    oogah;
  </pre>
  
  <h1>DESCRIPTION</h1>
  
  This module does things with stuff.  It exports these functions:
  
  <dl>
  <dt><code>thingify( ... )</code>
  <dd>This function takes stuff, and returns their value as things.
  
  <dt><code>destuffulate( ... )</code>
  <dd>This function returns the things, from stuff.
   <p>It will throw a fatal exception if applied to things.
   <br>So don't do that.
  
  <dt><code>enthinction( ... )</code>
  <dd>This is where I run out of ways to make up silly sentences
   involving "thing" and "stuff".  Mostly.
  
  </dl>
  
  <h2>Caveats and WYA's</h2>
  
  Things to be wary of:
  
  <ul>
  <li>The things.
  <li>And the stuff
   <p>Don't forget about that stuff.  Gotta keep an eye on that.
  </ul>
  
  <h1>BUGS</h1>
  
  Stuff is hard.
  
  <h1>SEE ALSO</h1>
  
  <a href="pod:Class::Classless">Class::Classless</a>,
  <a href="pod:strict">strict</a>,
  <a href="pod:Lingua::EN::Numbers::Ordinate"
   >Lingua::EN::Numbers::Ordinate</a>,
  <a href="pod:perlvar">perlvar</a>,
  
  <!-- I use the secret-sauce 'pod:' scheme as a back door for making
   simple cross-references to POD man pages -->
  
  <h1>COPYRIGHT</h1>
  
  Copyright 2000, Joey Jo-Jo Jr. Shabadoo.
  
  <!-- just one suggested phrasing for the license... -->
  <p>This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
  
  <h1>AUTHOR</h1>
  Joey Jo-Jo Jr. Shabadoo, <code>jojojo@shabadoo.int</code>
  </body>
  </html>

=head1 BUG REPORTS

If you do find a case where this converter misinterprets what you
consider straightforward HTML (which you should really really have run
thru an HTML syntax checker, by the way!), report it to me as a bug, at
C<sburke@cpan.org>.

Be sure to include the entire document that causes the error -- then
specify exactly what you consider the error to be.

=head1 BUGS AND CAVEATS

* Doesn't try to turn "smart quotes" characters into simple " and '.
Maybe should?

* Fails to turn

  foo thing&nbsp;bar&nbsp;baz quux

into

  foo S<thing bar baz> quux

I.e., currently just turns C<&nbsp;>'s into normal spaces.

* Numeric entities (C<EE<lt>numE<gt>>) are used when necessary -- but these
are not understood by some older POD converters.

* No HTML that you provide will turn into C<FE<lt>...E<gt>>

* Currently maps

  <A HREF="foo">bar</A>

to

  X<foo>bar

but is this correct?

=head1 SEE ALSO

L<perlpod>, L<Pod::Html>, L<HTML::TreeBuilder>

And HTML Tidy, at C<http://www.w3.org/People/Raggett/tidy/>

=head1 COPYRIGHT

Copyright (c) 2000 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

# TODO: test whether anchors and references to them actually work
#  in extremis?  (see what recent pod2html versions do to them?)

#--------------------------------------------------------------------------

sub convert {
  Carp::croak(__PACKAGE__ . '::convert needs parameters!')unless @_;
  Carp::croak(
    "odd number of elements in options to " . __PACKAGE__ . "::convert")
   if @_ % 2;

  my %o = @_;
  local($Debug) = $Debug;
  if(exists $o{'debug'}) { $Debug = $o{'debug'} }
  
  my $tree = HTML::TreeBuilder->new();
  
  $tree->ignore_ignorable_whitespace(1);
  
  my $comments = [ __PACKAGE__ . ' conversion notes:' ];
  
  if(exists $o{'tree'}) {
    $tree->delete; # never mind that one
    $tree = $o{'tree'};
    die "but the 'tree' value is undef" unless defined $tree;
    die "but the 'tree' value isn't an object" unless ref $tree;
    die "but the 'tree' value object's class isn't based on HTML::Element"
     unless $tree->isa('HTML::Element');
    $tree = $tree->clone;

  } else {

    if(exists $o{'file'}) {
      die "File $o{'file'} doesn't exist" unless -e $o{'file'};
      local(*IN);
      open(IN, "<$o{'file'}") or die "Can't open $o{'file'}: $!";
      $o{'handle'} = *IN{IO};
      ++$o{'_close_after'};
      print "Input from $o{'file'} ($o{'handle'})\n" if $Debug;
      push @$comments, "#From file $o{'file'}";
    }

    if(exists $o{'handle'}) {
      local $/;
      my $fh = $o{'handle'};
      my $x;
      $x = <$fh>;
      close($fh) if $o{'_close_after'};
      $o{'content'} = \$x;
      print "Input from handle ($o{'handle'})\n" if $Debug;
    }

    if(exists $o{'content'}) {
      my($content_r, $is_copy);
      if(!defined $o{'content'}) { # undef content?
        die "content is undef";
      } elsif(ref $o{'content'}) { # scalar ref
        die "content only accepts scalars or scalar refs"
          unless ref $o{'content'} eq 'SCALAR';
        $content_r = $o{'content'};
        $is_copy = 0;
      } else { # simple scalar
        $content_r = \$o{'content'};
        $is_copy = 1;
      }

      # Nativize newlines, if possible and if need be.
      # Otherwise PREs will be hard to reckon.
      if("\n" ne "\cm" and "\n" ne "\cm\cj" and "\n" ne "\cj") {
        print "I don't recognize what \"\\n\" means on this system!" if $Debug;
      } elsif($$content_r =~ m/(\cm\cj|\cm|\cj)/) {
        my $nl = $1;
        if($nl eq "\n") {
          # no-op
          print "# Already in native newline format\n" if $Debug;
        } else {
          unless($is_copy) {
            my $x = $$content_r;
            $content_r = \$x; # copy
            $is_copy = 1;
          }
          if($nl eq "\cm") {
            $$content_r =~ tr/\cm/\n/;
            print "# Nativizing newlines from \\cm to \\n\n" if $Debug;
          } elsif($nl eq "\cj") {
            $$content_r =~ tr/\cj/\n/;
            print "# Nativizing newlines from \\cj to \\n\n" if $Debug;
          } elsif($nl eq "\cm\cj") {
            $$content_r =~ tr/\cj//d;
            $$content_r =~ tr/\cm/\n/ unless "\cm" eq "\n";
            print "# Nativizing newlines from \\cm\\cj to \\n\n" if $Debug;
          }
        }
      }

      push @$comments,
        '# ' . length($$content_r) . ' bytes of input';
      $tree->parse($$content_r);
      $tree->eof;
      delete $o{'content'};
    } else {
      die "No input source specified?";
    }
  }

  {
    # The BODY is all we need.  Discard the rest.
    my $body = $tree->find_by_tag_name('body') || die "No BODY in tree?";
    $body->detach;
    $tree->delete;
    $tree = $body;
  }

  push @$comments, scalar(localtime) . ' ' . ($ENV{'USER'} || '');
  $tree->attr('_pod_comments', $comments);
  
  # More options:
  if($o{'a_name'}) {
    $tree->attr('_a_name', 1);
    push @$comments, " Will try to render <a name='...'>";
  } else {
    push @$comments,
     " No a_name switch not specified, so will not try to render <a name='...'>";
  }
  if($o{'a_href'}) {
    $tree->attr('_a_href', 1);
    push @$comments, " Will try to render <a href='...'>";
  } else {
    push @$comments,
     " No a_href switch not specified, so will not try to render <a href='...'>";
  }
  
  twist_tree($tree);

  my $rendering_r = tree_as_pod($tree);
  $tree->delete;
  return $$rendering_r;
}

###########################################################################
#
# The code below this point is not happy nice readable undocumented code.
# It is angry cryptic code, of the sort that you will find little use in
# reading.
#
# When I first thought of writing this module, several years ago, I had
# noble dreams that I could write some sort of universal markup-language
# mixmaster, which would only need be fed some information about the
# source language and the target language, and a few simple facts about
# what constructs are equivalent (that HTML "h1" is POD "head1", for
# example), and then magic would happen, and documents would be converted.
#
# Well, I've not yet found that mixmaster, so I've had to write some
# very spooky crusty strange code.  It seems to work rather well when fed
# simple HTML, and seems to degrade gracefully when fed too-complex HTML.
#
# The code can be used as-is, but it's not conceivably adaptable to other
# tasks, or even easily maintainable, regrettably.  However, as HTML or
# POD are not likely to mutate significantly any time soon, I think
# substantial maintenance will not be needed -- just minor tweaking or
# bugfixes on my part.
#
###########################################################################
#             SO STOP READING NOW, IF YOU VALUE YOUR SANITY
###########################################################################
#
# Stay away!
# STAY AWAY!
# Stay away!
# You might end up like me!
#
# It's the pain
# that keeps us alive,
# but that beauty is all that we need to survive.
# 
# That damned beauty is all that we need to survive.
#
#   -- David Byrne, "They Are In Love"
#
###########################################################################

# Initialization code:

# TODO: replace this with a hardwired table?
%Phrasal = %HTML::Tagset::isPhraseMarkup;
delete @Phrasal{'br', 'hr'};
for (qw(~literal ~texticle)) {  $Phrasal{$_} = 1 }
$counter = 0 unless defined $counter;

$Debug = 2 unless defined $Debug;

# Fill out Char2ent:
{
  die "\%HTML::Entities::char2entity is empty?"
   unless keys %HTML::Entities::char2entity;
  
  my($c,$e);
  while(($c,$e) = each(%HTML::Entities::char2entity)) {
    if($e =~ m{^&#(\d+);$}s) {
      $Char2ent{$c} = "E<$1>";
      #print "num $e => E<$1>\n";
       # &#123; => E<123>
    } elsif($e =~ m{^&([^;]+);$}s) {
      $Char2ent{$c} = "E<$1>";
      #print "eng $e => E<$1>\n";
       # &eacute; => E<eacute>
    } else {
      warn "Unknown thingy in %HTML::Entities::char2entity: $e"
      # if $^W;
    }
  }
  
  # Points of difference between HTML entities and POD entities:
  
  $Char2ent{"\xA0"} = "E<160>"; # there is no E<nbsp>
  
  $Char2ent{"\xAB"} = "E<lchevron>";
  $Char2ent{"\xBB"} = "E<rchevron>";
   # Altho new POD processors also know E<laquo> and E<raquo>
  
  # Old POD processors don't know these two -- so leave numeric
  # $Char2ent{'/'} = 'E<sol>';
  # $Char2ent{'|'} = 'E<verbar>';
}

# Set up some initial values we'll need later.
unless(defined $nbsp) {
  my $nb = '&nbsp;';
  HTML::Entities::decode_entities($nb);
  if(!defined $nb) {
    die "&nbsp; decodes to undef?";
  } elsif($nb eq '') {
    die "&nbsp; decodes to empty-string?";
  } elsif($nb eq '&nbsp;') {
    die "&nbsp; doesn't decode?";
  } elsif($nb eq ' ') {
    $nbsp = undef;
  } else {
    $nbsp = $nb;
  }
}

unless(defined $E_slash) {
  my $x = '/';
  encode_entities_harder($x);
  if(!defined $x or !length $x) {
    die "'/' encodes to nothing??";
  } elsif($x eq '/') {
    # no-op
  } elsif($x =~ m{^E<[^>]+>$}s) {
    $E_slash = $x;
  } else {
    die "'/' encodes as $x?!";
  }
}

unless(defined $E_vbar) {
  my $x = '|';
  encode_entities_harder($x);
  if(!defined $x or !length $x) {
    die "'|' encodes to nothing??";
  } elsif($x eq '|') {
    # no-op
  } elsif($x =~ m{^E<[^>]+>$}s) {
    $E_vbar = $x;
  } else {
    die "'|' encodes as $x?!";
  }
}

# Last chance to save your sanity: stop reading now...

#--------------------------------------------------------------------------

# TODO: make all P's go byebye once we've texticulated?

sub twist_tree {
  my $tree = $_[0];

  html_node_name($tree);

  delete_unknowns($tree);

  special_splice_div($tree);

  print("Input tree:\n"), $tree->dump, sleep(0) if $Debug;

  prune_by_tag_name( $tree,
   [qw~ script style ~],
   [qw~ map style isindex select textarea del input embed bgsound basefont ~],
  );

  splice_by_tag_name($tree,
   [qw~
    big small acronym sub sup multicol
    applet param object
    table tr caption col thead tbody tfoot colgroup
    noscript center font bdo fieldset ins
    form label legend button link layer object
    span abbr blink strike wbr
    frame frameset ilayer layer nolayer
    address nobr
   ~],
  );

  remap_tags($tree, {qw~
    td p
    th p
    em i
    strong b
    cite i
    code code
    tt code
    kbd code
    samp code
    var i
    dfn b
    listing pre
    plaintext pre
    xmp pre
    dd p
  ~});
  # CODE for C<>
  #    I for I<>
  #    B for B<>

  # TODO: Warn of cases where heading has too-complex text in it?

  p_unnest($tree);

  pre_render($tree);
  q_render($tree);

  images_render($tree);
  hr_render($tree);
  br_render($tree);
  lists_render($tree);
  #wrangle_body_children($tree);

  literalize_text_under($tree);

  winge_about_phrasal_paradoxes($tree);

  texticulate($tree);
  promote_some_secondary_children($tree);
  goodify_p_elements($tree);

  render_headings($tree); # busts up the headings

  a_tweak($tree);
  #bust_up($tree, qw~h1 h2 h3 h4 h5 h6 p~);

  pod_node_name($tree);
  $tree->dump, sleep(0) if $Debug > 1;
  return;
}

#==========================================================================
# Subs below here are in no particular order.  Ahwell.

sub a_tweak {
  
  #Scratch:
  my($a_name, $parent, $grandparent, $gptag, @cl, $text);
  
  foreach my $a ($_[0]->find_by_tag_name('a')) {
    # The configuration we're after looks like this:
     #  <h1 -pod-id="h1_1" id="`h1_1" was-tag="h1"> @0.0
     #    <~texticle -pod-id="~texticle_1" id="``G55"> @0.0.0
     #      <a -pod-id="a_1" id="`a_1" name="NAME"> @0.0.0.0
     #          NAME  @0.0.0.0.0
    $a_name = $a->attr('name');
    next unless defined $a_name;
    
    $parent = $a->parent || next;
    next unless $parent->tag eq '~texticle';
    $grandparent = $parent->parent || next;
    $gptag = $grandparent->tag;
    next unless $gptag eq 'h1' or $gptag eq 'h2' or $gptag eq 'item';
    next unless $parent->content_list == 1
      and $grandparent->content_list == 1; # only child of an only child
    @cl = $a->content_list; # with one child, a texticle
    next unless @cl == 1 and ref $cl[0] and $cl[0]->tag eq '~literal';
    $text = $cl[0]->attr('text');
    next unless defined $text;
    $text =~ s/^\s+//s;
    $text =~ s/\s+$//s;
    if($a_name eq $text) {
      $a->replace_with_content;
      print "a_tweak applies to ", $a->attr('id'), "\n" if $Debug > 1
    } else {
      print "a_tweak can't apply to ",
       $a->attr('id'), ": [$a_name] ne [$text]\n"
       if $Debug > 1;
      # hack can't apply
    }
  }
  
  return;
}

sub p_unnest {
  my $tree = $_[0];
  # Now, p's can't nest in HTML, but once we've spliced out and remapped
  # things, we can end up with p's containing p's in our parse tree:
  #    <table><td> Foo <table><td> Bar </td></table> baz </td></table>
  # =  <p> Foo <p> Bar </p> Baz </p>
  foreach my $p (reverse $tree->find_by_tag_name('p')) {
    if($p->parent->tag eq 'p') {
      my @c = $p->detach_content;
      $p->replace_with(
                       HTML::Element->new( 'br',
                                           'id', '``G' . ++$counter),
                       @c,
                       HTML::Element->new( 'br',
                                           'id', '``G' . ++$counter),
                      );
    }
  }
}

#==========================================================================

sub delete_unknowns {
  my $tree = $_[0];
  my $map_r = $tree->tagname_map;
  delete @$map_r{keys %HTML::Tagset::isKnown};
  my($tag, $elements);
  while(($tag,$elements) = each %$map_r) {
    commentate($tree, join ", ",
               "#  Unknown \"$tag\" elements deleted: ",
               map $_->attr('id'), @$elements
              );
    foreach my $e (@$elements) { $e->replace_with_content }
  }
  return;
}

#==========================================================================
sub special_splice_div {
  foreach my $div ($_[0]->find_by_tag_name('div', 'iframe')) {
    $div->replace_with(
                       HTML::Element->new( 'br',
                                           'id', '``G' . ++$counter),
                       $div->content_list(),
                       HTML::Element->new( 'br',
                                           'id', '``G' . ++$counter),
                      );
  }
  return;
}

#==========================================================================

sub winge_about_phrasal_paradoxes {
  my $tree = $_[0];
  my @non_phrasal_children;
  foreach my $p (reverse $tree->find_by_tag_name(keys %Phrasal)) {
    @non_phrasal_children = ();
    foreach my $c ($p->content_list) {
      push @non_phrasal_children, $c
        if ref $c and not $Phrasal{$c->tag};
    }
    if(@non_phrasal_children) {
      my $tag = $p->tag;
      commentate( $tree, 
                  join '',
                  " Deleting phrasal \"$tag\" element (",
                  $p->attr('id'),
                  ") because it has super-phrasal elements (",
                  join(", ",
                    map $_->attr('id'), @non_phrasal_children
                  ), ") as children.",
                )
      ;
      $p->replace_with_content;
    }
  }
  return;
}

#==========================================================================

sub commentate {
  my $tree = shift;
  push @{ $tree->attr('_pod_comments') }, @_;
  return;
}

#==========================================================================

sub html_node_name {
  my $map_r = $_[0]->tagname_map;

  my($name, $nodes);
  while(($name, $nodes) = each %$map_r) {
    my $counter = 0;
    foreach my $node (@$nodes) {
      ++$counter;
      $node->attr('id',
                  $node->attr('id') || ( '`' . $name . '_' . $counter )
                 )
      ;
    }
  }

  return;
}

sub pod_node_name {
  my $map_r = $_[0]->tagname_map;

  my($name, $nodes);
  while(($name, $nodes) = each %$map_r) {
    my $counter = 0;
    foreach my $node (@$nodes) {
      ++$counter;
      $node->attr('-pod-id',
                  $name . '_' . $counter
                 )
      ;
    }
  }

  return;
}

#==========================================================================

sub render_headings {
  my $tree = $_[0];
  my $map_r = $tree->tagname_map;
  my @levels = sort grep m/^h[1-9]+$/s, keys %$map_r;
  my @headings;

  if(@levels == 0) { # no headings!?!
    # TODO: insert something?
  } else {
    print "# Highest heading level: $levels[0]  Making that =head1\n"
     if $Debug;
    foreach my $h (@{$map_r->{shift @levels}}) {
      push @headings, $h;
      $h->attr('was-tag', $h->tag);
      $h->attr('_tag', 'h1');
    }
    # And, for any sub-primary levels...
    print "# Lower levels: @levels.  Making those =head2\n"
     if @levels and $Debug;
    foreach my $h (map @{$map_r->{$_}}, @levels) {
      push @headings, $h;
      $h->attr('was-tag', $h->tag);
      $h->attr('_tag', 'h2');
    }
  }

  foreach my $h (@headings) {
    if($h->parent->is_inside('h1', 'h2')) {
      # Don't put headings inside other headings.  It's just stupid.
      $h->replace_with_content;
      undef($h);
    }
  }

  foreach my $h (grep defined($_), @headings) {
    my @c = $h->content_list;
    if(!@c) {
      $h->delete;
    } elsif($c[0]->tag ne '~texticle') {
      $h->replace_with_content;
       # Don't have things other than texticles in headings
    } else {
      if(@c > 1) {
        # promote all but the first element
        $h->detach_content;
        $h->push_content(shift @c);
        $h->postinsert(@c);
        # SHOULD HAVE HAPPENED ANYWAY.
      }
       # else @c is just one element, a texticle -- which is ideal.
      commentate($tree,
                 "# Icky: heading " . $h->attr('id')
                 . " not immediately under body."
                ) unless $h->parent eq $tree;
    }
  }

  return;
}

#--------------------------------------------------------------------------

sub goodify_p_elements {
  foreach my $x ($_[0], $_[0]->find_by_tag_name('over', 'item')) {
    my $dirty;
    my @children = $x->content_list;
    
    for(my $i = 0; $i < @children; ++$i) {    
      if($children[$i]->tag eq 'p') {
        my $p = $children[$i];
        my @p_content = $p->detach_content;
        $p->delete;
        $dirty = 1;

        # Replace the p in the list with its content, and update $i:
        splice @children, $i, 1, @p_content;
        $i += scalar(@p_content) - 1;
         # Properly,
         #  Leaves $i alone if @p_content == 1.
         #  Decrements $i if @p_content == 0.
         #  Adds to $i appropriately for other sizes of @p_content.
      }
    }
    
    if($dirty) {
      $x->detach_content;
      $x->push_content(@children);
    }
  }

  my @c;
  # /Try/ to delete all p's
  foreach my $p ($_[0]->find_by_tag_name('p')) {
    @c = $p->content_list;
    if(!@c) {
      $p->delete;  # always right?

    } elsif(@c == grep {; $_->tag eq '~texticle'} @c) {
      #all texticles!
      $p->replace_with_content;
    } else {
      print
        "# Odd: content of p (",
        $p->attr('id'),
        ") is not all texticles: [",
        join(' ', map $_->tag, @c), "]\n"
      ;
      # Shouldn't happen, I think.
    }
  }

  return;
}

#--------------------------------------------------------------------------

sub promote_some_secondary_children {
  foreach my $x (reverse($_[0]->find_by_tag_name('item', 'h1' .. 'h6'))) {
    my @c = $x->content_list;
    if(@c > 1) {
      # Take all children after the first, and move them up to
      #  being right sisters of this node.
      print
        "# Promote_some_secondary_children applies to ",
        $x->attr('id'),
        ": (",
        join(", ", map $_->attr('id'), @c), ")\n" if $Debug;
      $x->detach_content;
      $x->push_content(shift @c);
      $x->postinsert(@c);
      #print "Done\n" if $Debug;
    }
  }
  #print "Returning\n" if $Debug;
  return;
}

sub literalize_text_under {
  # Traverse tree, turning text segments into ~literal pseudoelements
  my $node = $_[0];
  my(@children, $dirty);
  foreach my $c (@children = $node->content_list) {
    if(ref $c) {
      literalize_text_under($c);
    } else {
      $dirty = 1;
      $c = HTML::Element->new('~literal', 'text' => $c,
                              'id', '``G' . ++$counter);
    }
  }
  if($dirty) {
    $node->detach_content;
    $node->push_content(@children);
  }
  return;
}

#--------------------------------------------------------------------------

sub texticulate {
  # group ~literals and phrasals into texticles
  #  -- maximally high-and-merged phrasal/text groups
  my $node = $_[0];
  my $dirty;
  my(@children) = $node->content_list;

  #foreach my $c (@children) {
  #  texticulate($c);
  #}

  #print "Applying to $node = ", $node->tag, "\n";

  if(! $Phrasal{$node->tag}) {
    # Only non-phrasals can have texticles as children!
    my $last_tag;
    for(my $i = 0; $i < @children; $i++) {
      texticulate($children[$i]); # RECURSE!
      next unless $Phrasal{$children[$i]->tag};
  
      if($i == 0
         or
         !$Phrasal{
           $last_tag = $children[$i - 1]->tag
         }
      ) {
        # start a new texticle group
        $dirty = 1;
        my $old = $children[$i];
        $children[$i] = HTML::Element->new('~texticle',
                                           'id', '``G' . ++$counter);
        $children[$i]->push_content($old); # and demote the phrasal to under it
      } elsif($last_tag eq '~texticle') {
        # move this under preceding texticle
        $dirty = 1;
        $children[$i - 1]->push_content( splice @children, $i, 1 );
        --$i;
      } else {
        die "SPORK 1231233312!";      
      }
    }
    
    #if(0) {
    #  foreach my $c (@children) {
    #    # Now fold the texticular content up
    #    if($c->tag eq '~texticle') {
    #      $c->attr('~folded' => [$c->detach_content]);
    #    }
    #  }
    #}
  }

  # Now delete all br's!
  #  (Would it be better to delete BRs only adjacent to a texticle?)
  for(my $i = 0; $i < @children; $i++) {
    if($children[$i]->tag eq 'br') {
      splice @children, $i, 1;
      --$i;
      $dirty = 1;
    }
  }
  # So, the only purpose/effect of BRs is that they serve as barriers
  # to unifying adjacent phrasal elements under a common texticle.
  # Once we've unified things, we just delete them from the tree.

  if($dirty) {
    $node->detach_content;
    $node->push_content(@children);
  }
}

#==========================================================================

sub remap_tags {
  my($tree, $hr) = @_;
  die unless $hr and ref($hr) eq 'HASH';
  my($recursor, $tag);
  $recursor = sub {
    foreach my $c ($_[0]->content_list) {
      if(ref $c) {
        if(($tag = $c->tag) and defined $tag and exists $hr->{$tag}) {
          $c->attr('_tag', $hr->{$tag});
        }
        $recursor->($c);  # recurse!
      }
    }
    return;
  };
  
  $recursor->($tree); # Run the recursion.
  
  undef $recursor;  # So the lambda's refcount can hit 0, and can GC.
  return;
}

#--------------------------------------------------------------------------

sub wrangle_body_children {
  my $tree = $_[0];
  my @children = $tree->content_list;
  my $dirty = 0;

  my $c;
  $tree->normalize_content; # NB: doesn't recurse

  for(my $i = 0; $i < @children; ++$i) {
    my $c = $children[$i];
    if(!ref($c)) {
      # put under a new p
      $dirty = 1;
      (
       $children[$i] = HTML::Element->new('p', 'superimplicit' => 1,
                                          'id', '``G' . ++$counter
                                         )
      )->push_content($c);
    #} elsif($c->tag eq 'hr') {
    #  # do anything special?
    }
  }

  if($dirty) {
    $tree->detach_content;
    $tree->push_content(@children);
  }

  return;
}

#--------------------------------------------------------------------------

sub lists_render { # Recursive.
  my $node = $_[0];
  my $tag;
  if(($tag = $node->tag) eq 'ul' or $tag eq 'menu') {
    $node->attr('was-tag', $tag);
    $node->attr('_tag', 'over');
    foreach my $c ($node->content_list) {
      next unless ref($c) and $c->tag eq 'li';
      $c->attr('_tag', 'item');
      $c->unshift_content('* ');
      # TODO: support bullet types other than this?
    }

  } elsif($tag eq 'ol') {
    $node->attr('was-tag', $tag);
    $node->attr('_tag', 'over');
    my $x = 0;
    foreach my $c ($node->content_list) {
      next unless ref($c) and $c->tag eq 'li';
      $c->attr('_tag', 'item');
      $c->unshift_content(++$x . '. ');
      # TODO: support number styles other than this?
    }

  } elsif($tag eq 'dl') {
    $node->attr('was-tag', $tag);
    $node->attr('_tag', 'over');
    my $tag;
    foreach my $c ($node->content_list) {
      next unless ref($c);
      if(($tag = $c->tag) eq 'dt') {
        $c->attr('was-tag', $tag);
        $c->attr('_tag', 'item');
      } elsif($tag eq 'dd') {
        $c->attr('was-tag', $tag);
        $c->attr('_tag', 'item');
         # Altho really, earlier on, we will have turned all dd's into p's!
         # This code is here just in case we decide that that wasn't
         #  such a hot idea.
         # Instead of turning dd's into items, consider replacing with
         #  content, with a br on each side?  Or too late for that?
      }
       # else just moooove along
    }

  } elsif($tag eq 'blockquote') { # not really a list, but hey.
    $node->attr('was-tag', $tag);
    $node->attr('_tag', 'over');
  }

  # In any case, recurse...
  foreach my $c ($node->content_list) {
    lists_render($c) if ref $c;
  }
}

#--------------------------------------------------------------------------

sub br_render {
  # render BRs.

  # TODO: anything necessary?

  return;
}


sub hr_render {
  my $tree = $_[0];
  my $alt;
  foreach my $hr ($tree->find_by_tag_name('hr')) {
    if($hr->parent->tag eq 'body') {
      # Special sauce.  SPECIAL SAUCE!
      $hr->attr('_tag', 'p');
      $hr->attr('was-tag', 'hr');
      $hr->push_content('----');
    } else {
      $hr->replace_with(
        $hr->new('br', 'was-tag' => 'hr', 'id' => '``G' . ++$counter),
        '----',
        $hr->new('br', 'was-tag' => 'hr', 'id' => '``G' . ++$counter),
      );
    }
  }
  return;
}


sub pre_render {
  my $tree = $_[0];
  foreach my $p ($tree->find_by_tag_name('pre')) {
    # Delete left or right ignorable WS nodes...
    {
      my $left = $p->left;
      #print "Left of $p is $left\n";
      if(defined $left and !ref $left and $left =~ m<^\s*$>s) {
        # all nil or WS.
        #print "Delendum left at", $p->attr('id') || $p->address, "!\n";
        $p->parent->splice_content($p->pindex - 1, 1); # delete preceding WS.
      }
    }
    {
      my $right = $p->right;
      if(defined $right and !ref $right and $right =~ m<^\s*$>s) {
        # all nil or WS.
        #print "Delendum right at", $p->attr('id') || $p->address, "!\n";
        $p->parent->splice_content($p->pindex + 1, 1); # delete following WS.
      }
    }

    # Now acually render, simply...
    my $text_content = $p->as_text;
    unless($text_content =~ m/\S+/) {
      $p->delete;
      next;
    }
    
    $text_content =~ s/^\n+//s; # Kill leading newlines
    $text_content =~ s/\n+$//s; # Kill trailing newlines

    my $left = $p->left;
    if($left and ref($left) and $left->tag eq 'pre') {
      # prepend to the immediately preceding pre's content
      ${
        $left->attr('~pre_content_r')
      } .= "\n" . $text_content;
      $p->delete;
    } else {
      $p->delete_content;
      $p->attr('~pre_content_r', \$text_content);
        #print "Pre content [[",$text_content,"]]\n";
    }
  }
  return;
}

sub q_render {
  my $tree = $_[0];
  foreach my $q ($tree->find_by_tag_name('q')) {
    $q->push_content('"');
    $q->unshift_content('"');
    $q->replace_with_content;
  }
  return;
}

sub images_render {
  my $tree = $_[0];
  foreach my $img ($tree->find_by_tag_name('img')) {
    my $alt;
    if(defined($alt = $img->attr('alt'))) {
      $img->replace_with($alt);
    } else {
      $img->replace_with(
                         $Debug ? 
                         ('[IMAGE' . $img->attr('id') . ']') :
                         '[IMAGE]'
                        );
      #?? $img->delete;
    }
  }
  return;
}

#--------------------------------------------------------------------------

sub prune_by_tag_name {
  my($tree, @o) = @_;
  foreach my $o (@o) {
    foreach my $x ($tree->find_by_tag_name(ref $o ? @$o : $o)) {
      $x->delete;
    }
  }
  return;
}

sub splice_by_tag_name {
  my($tree, @o) = @_;
  foreach my $o (@o) {
    foreach my $x ($tree->find_by_tag_name(ref $o ? @$o : $o)) {
      $x->replace_with_content;
    }
  }
  return;
}

#--------------------------------------------------------------------------
sub tree_as_pod {
  my $tree = $_[0];

  my @lines;
  my $comments = $tree->attr('_pod_comments');

  my $bender;

  $bender = sub {
    my(@post, $node);
    my $tag = ($node = $_[0])->tag;

    if($tag eq 'body') {
      # no-op
    } elsif($tag eq 'pre') {
      push @lines, ${$node->attr('~pre_content_r')};
      $lines[-1] =~ s/^/ /gm if $lines[-1] =~ m/^\S/m;
       # bump everything over if there's any lines that start with
       #  anything non-spaceys
      while($lines[-1] =~ s/\n\n/\n \n/) { }
       # have there be no zero-length lines.
    } elsif($tag eq 'over') {
      push @lines, "=over";
      push @post,  "=back";
    } elsif($tag eq 'item') {
      push @lines, "=item";
    } elsif($tag eq 'h1') {
      push @lines, "=head1";
    } elsif($tag eq 'h2') {
      push @lines, "=head2";
    } elsif($tag eq '~texticle') {
      my $text = render_texticle($tree,$node);
      $text =~ s/^\s+//s;
      $text =~ s/\s+$//s;
      $text =~ s/^=/E<61>/s;
       # So that this can't be mistaken for a directive -- on the
       #  off chance that text content starts with a '='
       
      #$text = "{$text}";
      
      if(
        @lines and
        $lines[-1] =~ m/^=(\w{1,10})$/s and
        ( $1 eq 'item' or $1 eq 'head1' or $1 eq 'head2' )
      ) {
        # Merge this text with the directive:
        $text = pop(@lines) . ' ' . $text;
      }
      
      push @lines, wrap72_dammit($text);
      $lines[-1] =~ s/\s+$//s;  # Make REALLY sure there's no tailing WS
      pop @lines unless length $lines[-1];  # Sanity check.
      
      return;
       # Don't recurse under texticles (because nothing should be there!)
    } else {
      print "unrenderable element \"$tag\" in phrasal-pass\n" if $Debug;
    }
    
    foreach my $c ($node->content_list) {
      $bender->($c);
    }
    
    push @lines, @post;
    return;
  };
  $bender->($tree);
  undef $bender;

  unshift @lines, "=pod" unless @lines and $lines[0] =~ m<^=>s;

  push @lines, "=cut\n\n"; # get extra double-newline at end

  my $pod = join "\n\n", @lines;

  if($comments and @$comments) {
    foreach my $c (@$comments) {
      $c =~ tr<\cm\cj>< >s;
      $c = "#" . $c unless $c =~ m<^\s*#>s;
    }
    $pod .= join "\n", @$comments, '';
  }

  sleep(0), print("#Start pod\n\n$pod\n"), sleep(0) if $Debug > 1;
  return \$pod;
}

#--------------------------------------------------------------------------
sub render_texticle {
  my($tree, $t) = @_;
  my $text = '';
  my $bender;
  
  my $a_name = $tree->attr('_a_name');
  my $a_href = $tree->attr('_a_href');
  
  my $under_l_count = 0;
  $bender = sub {
    my $tag = (my $node = $_[0])->tag;
    my $post = '>';
    my $decr_under_l_count_post = 0;
    if($tag eq '~texticle') {
      # no-op -- just a container
      $post = '';
    } elsif($tag eq '~literal') {
      my $content = $node->attr('text');
      #print "Text from ~literal : ", $node->attr('text'), "\n";
      $content =~ s/\Q$nbsp/ /og if defined $nbsp;
       # Kill nbsps.  Why?
       # First off, most of them are lame editor artifacts.
       # Second off, actually treating them correctly (with S<...>)
       #  would be a real pain.

      if($under_l_count) {
        encode_entities_harder($content);
      } else {
        encode_entities($content);
      }
      #if(defined $E_slash) {
      #  # Delete at least most of the optional E<sol>'s
      #  while( $content =~ s{^([^<>]*)\Q$E_slash\E}{$1/}so ) {}
      #  while( $content =~ s{\Q$E_slash\E([^<>]*)$}{/$1}so ) {}
      #}
      #if(defined $E_vbar) {
      #  # Delete at least most of the optional E<verbar>'s
      #  while( $content =~ s{^([^<>]*)\Q$E_vbar\E}{$1|}so ) {}
      #  while( $content =~ s{\Q$E_vbar\E([^<>]*)$}{|$1}so ) {}
      #}
      print "\$text is undef?" unless defined $content;
      $text .= $content;
      $post = '';
    } elsif($tag eq 'code') {
      $text .= 'C<';
    } elsif($tag eq 'i') {
      $text .= 'I<';
    } elsif($tag eq 'b') {
      $text .= 'B<';
    } elsif($tag eq 'a') {
      my($name, $href);
      $name = $a_name ? $node->attr('name') : undef;
      $href = $a_href ? $node->attr('href') : undef;
      $post = '';

      if(defined $name and length $name) {
        $text .= 'X<' . $name . '>';
      }

      if(defined $href and length $href) {
        encode_entities($href);
        #print "{Link text:{$href}}\n";
        if($href =~ s/^#//s) {
          # internal relative href
          $text .= 'L<';
          $post .= "|/$href>";
          ++$under_l_count;
          $decr_under_l_count_post = 1;
        } elsif($href =~ s/^pod://s) {
          # Pass that thru.
          # A back door for making straightforward pod links.
          $text .= 'L<';
          $post .= "|$href>";
          ++$under_l_count;
          $decr_under_l_count_post = 1;
        } elsif($href =~ m<^[-+.a-z0-9A-Z]+\:[^:]>s) {
          # It matches RFC 1738's idea of an absolute URL.
          # Pass it thru: the podulator should detect that it's a URL
          # and handle appropriately.
          $post .= " ($href)";
        } else {
          # a relative link??
          $href = $href;
          commentate($t->root, "# Untranslatable link: \"$href\"");
        }
      }
    } else {
      print "Unrenderable sub-phrasal element $tag: ignoring\n";
      $post = '';
    }

    # Recurse!
    foreach my $c ($node->content_list) {
      $bender->($c);
    }
    
    # Now, post-order things:
    
    $text .= $post;
    $under_l_count-- if $decr_under_l_count_post;
    return;
  };
  $bender->($t);
  undef $bender;

  $text =~ s/\s+/ /g;

  # A weensy bit of cleanup:
  $text =~ s/ ?> ?$/>/s;
  $text =~ s/^((?:\w<)+) ([^>])/$1$2/;

  #print "{$text}\n";

  return $text;
}

#--------------------------------------------------------------------------
sub COLMAX () {72}

sub wrap72_dammit {
  # All because Text::Wrap::wrap DIES when it hits an unwrappably
  #  large text chunk, DAMMIT.

  # So this is a stupid wrapper: knows nothing about tabs or anything.
  my $text = '';
  my $col = 0;
  foreach my $w (split /\s+/, $_[0]) {
    next unless length $w;
    if(length($w) >= COLMAX) {
      # Unwrappably large chunk.
      if($col) {
        $text .= "\n$w\n";
      } else {
        $text .= "$w\n";
      }
      $col = 0;
    } elsif ((1 + $col + length $w) < COLMAX) {
      # The word will fit on /this/ line
      if($col) {
        $text .= " $w";
        $col += 1 + length $w;
      } else {
        $text .=   $w ;
        $col +=     length $w;
      }
    } else {
      # Start a new line
      if($col) {
        $text .= "\n$w";
      } else {
        $text .=    $w; # never applies?
      }
      $col = length $w;
    }
  }
  $text =~ s/\n+$//s; # nix and trailing newlines

  return $text;
}


#==========================================================================
# Adapted from Gisle Aas's HTML::Entities::encode_entities:

sub encode_entities {
  $_[0] =~ s/([^\n\t !-;=?-~])/$Char2ent{$1}/g;
    # Encode control chars, high bit chars and '<' and '>'
  return;
}

sub encode_entities_harder {
  $_[0] =~ s/([^\n\t !\#\$%\'-.0-=?-{}~])/$Char2ent{$1}/g;
    # Encode control chars, high bit chars and '<', '&', '>', '"',
    # '|', '/'
  return;
}

#--------------------------------------------------------------------------

__END__

#     #
#     #  #    #  #    #   ####   ######  #####
#     #  ##   #  #    #  #       #       #    #
#     #  # #  #  #    #   ####   #####   #    #
#     #  #  # #  #    #       #  #       #    #
#     #  #   ##  #    #  #    #  #       #    #
 #####   #    #   ####    ####   ######  #####



sub bust_up {
  # In case some elements are too low in the tree, promote them.
  # And if they've got right siblings, make a faked-out new lineage
  #  for them.

  my($tree, @element_names) = @_;
  return unless $tree and @element_names;
  my($parent, $ptag, @left);
  foreach my $n (reverse($tree->find_by_tag_name(@element_names))) {
    next unless $parent = $n->parent; # must be delendum
    $ptag = $parent->tag;
    if($ptag eq 'body' or $ptag eq 'over') {
      next;
       # the ideal case.
    }
    
    @left = $ptag->left;
    
  }
  return;
}

#==========================================================================

#--------------------------------------------------------------------------

sub linked_dupe {
  my(@new, $prev, $this);
  foreach my $x (@_) {
    push @new, $this = HTML::Element->new($x->tag,
                                          $x->all_external_attr(),
                                          'id', '``G' . ++$counter,
                                         );
    $prev->push_content($this) if $prev; # link to prev
    $prev = $this;
  }
  return @new;
}

sub lineage_dupe {
  my $node = $_[0];
  my @lineage = reverse $node->lineage;
  shift @lineage; # Nix the BODY on top
  print "ZAZ: ", join(' ', map $_->tag, @lineage), "\n";
  return linked_dupe(@lineage);
}

#==========================================================================

sliced from &render_headings ...

  foreach my $h (grep defined($_), @headings) {
    unless($h->parent eq $tree) {
      my @lineage = reverse $h->lineage; # so it starts with body...
      my $second_ancestor = $lineage[1];
      my @right = $h->right;

      if(@right) {
        my @clonio = lineage_dupe($h);
        print "Clonio: ", join(' ', map $_->tag, @clonio);
        $clonio[-1]->push_content(@right);
        $second_ancestor->postinsert($clonio[0]);
      } else {
        $h->detach;
        $second_ancestor->postinsert($h);
      }

       # TODO: delete up the tree from $lineage[-1]
       #  in case of empty nodes? Or mark for later inspection
       #  for such possible deletion?
       # Consider: <em><h1>x</h1><h1>x</h1></em>
       #  The em(s) should just be optimized away

       # That transform is trickier than I thought.
    } 
  }
