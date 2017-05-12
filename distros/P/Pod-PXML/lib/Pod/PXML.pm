
#Time-stamp: "2004-12-29 18:34:27 AST"
#TODO: for xml2pod:
#    Make utf8/Latin-1 an option (default utf8?)
#    Make E<>ification an option (default to all)
#    Option for whether to delete highbit things in codeblocks (default: no?)
#TODO: for pod2xml:
#    Option: choice of XML encoding (Latin-1 or UTF-8)
#    Option: whether to represent things as literals, or as numeric entities.
#           (and whether to use decimal entities, or hex??)

require 5;
package Pod::PXML;
use strict;
use vars qw($VERSION $XMLNS %Char2podent %Char2xmlent
 $LATIN_1 $XML_VALIDATE $LINK_TEXT_INFER $FUSE_ADJACENT_PRES
 $HIGH_BIT_OK
);
$XMLNS = 'http://www.perl.com/CPAN/authors/id/S/SB/SBURKE/pxml_0.01.dtd';
$VERSION = '0.12';
 # I'm going to try to keep the major version numbers in the DTD and the
 #  module in synch.  I dunno about the fractional part, tho.
$LATIN_1 = 1;
$XML_VALIDATE = 1;
$HIGH_BIT_OK = 0;

$LINK_TEXT_INFER = 0;

$FUSE_ADJACENT_PRES = 1;
  # Whether to make " foo\n\n bar" as a single PRE,
  #  as if it were from " foo\n \n bar\n\n"
  # TODO: set to 1

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }

my $nil = [];

use Carp;
use utf8;

# POD entities are just HTML entities plus verbar and sol
#------------------------------------------------------------------------

# Fill out Char2podent, Char2xmlent.
{
  use HTML::Entities ();
  die "\%HTML::Entities::char2entity is empty?"
   unless keys %HTML::Entities::char2entity;
  
  my($c,$e);
  while(($c,$e) = each(%HTML::Entities::char2entity)) {
    if($e =~ m{^&#(\d+);$}s) {
      $Char2podent{ord $c} = "E<$1>";
      #print "num $e => E<$1>\n";
       # &#123; => E<123>
      # $Char2xmlent{ord $c} = $e;
    } elsif($e =~ m{^&([^;]+);$}s) {
      $Char2podent{ord $c} = "E<$1>";
      #print "eng $e => E<$1>\n";
       # &eacute; => E<eacute>
      # $Char2xmlent{ord $c} = $e;
    } else {
      warn "Unknown thingy in %HTML::Entities::char2entity: $c => $e"
      # if $^W;
    }
  }
  
  # Points of difference between HTML entities and POD entities:
  
  $Char2podent{ord "\xA0"} = "E<160>"; # there is no E<nbsp>
  
  $Char2podent{ord "\xAB"} = "E<lchevron>";
  $Char2podent{ord "\xBB"} = "E<rchevron>";
   # Altho new POD processors also know E<laquo> and E<raquo>
  
  # Old POD processors don't know these two -- so leave numeric
  # $Char2podent{ord '/'} = 'E<sol>';
  # $Char2podent{ord '|'} = 'E<verbar>';
  
  # And a few that we have to make completely sure are present.
  $Char2xmlent{ord '"'} = '&quot;' ;
  $Char2xmlent{ord '<'} = '&lt;'   ;
  $Char2xmlent{ord '>'} = '&gt;'   ;
  $Char2podent{ord '<'} = 'E<lt>'  ;
  $Char2podent{ord '>'} = 'E<gt>'  ;
}

#print STDERR "Sanity:  214 is ", $Char2podent{214}, "\n";

#------------------------------------------------------------------------

sub pod2xml ($) {
  require Pod::Tree;
  
  my $content = $_[0];

  my $tree = Pod::Tree->new;
  if(ref($content) eq 'SCALAR') {
    $tree->load_string($$content);
  } else {
    $tree->load_file($content);
  }
  unless($tree->loaded) { croak("Couldn't load pod") }
  return _pod_tree_as_xml($tree);
}

#------------------------------------------------------------------------
# Real work:

sub _pod_tree_as_xml {
  my $root = $_[0]->get_root;
  DEBUG > 2 and print "TREE DUMP: <<\n", $_[0]->dump, ">>\n\n";
  
  return "<!-- no pod -->\n\n" unless $root;
  my $out = '';

  my $trav;
  my $x; # scratch
  $trav = sub {
    my $it = $_[0];
    my $type = $it->get_type;
    my $post = '';
    DEBUG and print "Hitting $type\n";
    if($type eq 'root') {
      $out .= join "\n", 
        qq{<?xml version="1.0" encoding="UTF-8" ?>},
        qq{<!DOCTYPE pod PUBLIC "-//Sean Michael Burke//DTD PXML 0.01//EN"},
        qq{ "$XMLNS">},
        qq{<pod xmlns=\"$XMLNS\">},
        "<!-- (translated from pod, by " . __PACKAGE__ . " v$VERSION) -->",
        '',
        '',
      ;

      $post = "</pod>\n";  # harmless newline, I figure.
      
    } elsif($type eq 'for') {
      $out .= "<for target=\"" . xml_attr_escape($it->get_arg) . "\">";
      $out .= xml_escape_maybe_cdata($it->get_text);
      $out .= "</for>\n\n";
      return;
      
    } elsif($type eq 'sequence') {
      $type = lc($it->get_letter);
      DEBUG and print "Sequence type \"$type\"\n";
      if($type eq 'e') {
        # An unresolved entity.
        $x = $it->get_children;
        if($x and @$x ==1 and $x->[0]->get_type eq 'text') {
          $x = $x->[0]->get_text;
          die "Impossible entity name \"$x\"" if $x =~ m/[ \t<>]/s;
            # minimal sanity
          $out .= '&' . $x . ';';
        } else {
          # $out .= '&WHAT;';
          die "Aberrant E<..> content \"", $it->get_deep_text, "\"";
        }
        return;
      } elsif($type eq 'l') {
        # At time of writing, Pod::Tree is less than sterling in its
        #  treatment of L<...> sequences.

        #use Data::Dumper;
        #print "LINK DUMP: {{\n", Dumper($it), "}}\n";
        
        # Some special treatment...
        my $target = $it->get_target || die 'targetless link?';
                
        my($page, $section);
        $out .= "<link";
        $page = xml_attr_escape( $target->get_page );
        $out .= " page=\"$page\"" if length $page;
        $section = xml_attr_escape( $target->get_section );
        $out .= " section=\"$section\"" if length $section;
        $out .= ">";
        
        #if(!$LINK_TEXT_INFER and not(($x = $target->get_children) and @$x)) {
        unless(($x = $target->get_children) and @$x) {
          # There was no gloss (i.e., the bit after the "|").
          if(! $LINK_TEXT_INFER) {
            # subvert the normal processing of children of this sequence.
            $out .= "</link>";
            return;
          } else {
            # Infer the text instead.
            my $ch;
            if(($ch = $it->get_children) and @$ch == 1
               and $ch->[0]->get_type eq 'text'
            ) {
              # So this /is/ just some text bit that Pod::Tree implicated.

              # To replicate Pod::Text's inscrutible weirdness as
              #  best we can, for sake of continuity if not actual
              #  good sense or clarity.

              # The moral of the story is to always have L<text|...> !!!

              $x = '';
              if (!length $section) {
                  $x = "the $page manpage" if length $page;
              } elsif ($section =~ m/^[:\w]+(?:\(\))?/) {
                  $x .= "the $section entry";
                  $x .= (length $page) ? " in the $page manpage"
                                       : " elsewhere in this document";
              } else {
                  $section =~ s/^\"\s*//;
                  $section =~ s/\s*\"$//;
                  $x .= 'the section on "' . $section . '"';
                  $x .= " in the $page manpage" if length $page;
              }
              $out .= "$x</link>";
              return; # subvert the usual processing.
            }
             # Else it's complicated and scary.  Fall thru.
          }
        }
        $post = '</link>';
        
      } else {
        # Unknown sequence.  Ahwell, pass thru.
        $out .= "<$type>";
        $post = "</$type>";
      }
    } elsif($type eq 'list') {
      $x = xml_attr_escape($it->get_arg);
      $out .= length($x) ? "<list indent=\"$x\">\n\n" : "<list>\n\n";

      # used to have:
      #   sprintf "<list type=\"%s\" indent=\"%s\">\n\n",
      #     xml_attr_escape($it->get_list_type),
      #     xml_attr_escape($it->get_arg) ;

      $post = "</list>\n\n";

    } elsif($type eq 'ordinary') {
      $out .= "<p>";
      $post = "</p>\n\n";

    } elsif($type eq 'command') {
      $x = $it->get_command();
      if($x =~ m/^head[1234]$/is) {
        $x = lc($x);
        $out .= "<$x>";
        $post = "</$x>\n\n";
      } else {
        die "Unknown POD command \"$x\"";
      }
      
    } elsif($type eq 'item') {
      # Needs special recursion!
      $out .= '<item>';
      # used to have: sprintf '<item type="%s">',
      #           xml_attr_escape($it->get_item_type);

      # Recurse for the item's children:
      foreach my $c (@{ $it->get_children || $nil }) { $trav->($c) }
      $out .= "</item>\n\n";

      # Then recurse for the bastards further down...
      
    } elsif($type eq 'verbatim') {
      ( $FUSE_ADJACENT_PRES and $out =~ s/<\/pre>\n\n$//s )
       or $out .= "<pre>";
       # possibly combine adjacent verbatims into a single 'pre'
      $out .= xml_escape_maybe_cdata("\n" . $it->get_text . "\n");
      $out =~ s/]]><!\[CDATA\[// if $out =~ m/]]>$/s;
       # combining adjacent CDATA sections is nice, and always harmless
      $out .= "</pre>\n\n";
      return;
      
    } elsif($type eq 'text') {
      $out .= xml_escape($it->get_text);
      return;
      
    } else {
      $out .= "\n<!-- unknown podtree node type \"$type\" -->\n";
      return;
    }

    foreach my $c (@{    # Recurse...
      (($type eq 'item') ? $it->get_siblings() : $it->get_children())
      || $nil
    }) { $trav->($c) }

    $out .= $post;
    return;
  };
  $trav->($root);
  undef $trav;  # break cyclicity
  print "\n\n" if DEBUG;

  sanitize_newlines($out);

  return $out;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub xml_escape_maybe_cdata {  # not destructive
  my $x;
  $x = '' unless defined($x = $_[0]);
  if($x =~ m/[&<>]/ and not $x =~ m/[^\x00-\x80]/) {
    # CDATA only if uses those [&<>], and does not use anything highbit.
    $x =~ s/]]>/]]>]]&gt;<!\[CDATA\[/g;  # "escape" any ]]'s
    $x = "<![CDATA[" . $x . "]]>";
  } else {
    # Otherwise escape things.
    $x =~ s/&/&amp;/g;
    $x =~ s/</&lt;/g;
    $x =~ s/>/&gt;/g;
    
    #$x =~ s/([^\x00-\x7E])/$Char2xmlent{ord $1} or "&#".ord($1).";"/eg;
    $x =~ s/([^\x00-\x7E])/"&#".ord($1).";"/eg unless $HIGH_BIT_OK;
    
    # Why care about highbittyness?  Even tho we're declaring this content
    #  to be in UTF8, might as well entitify what we can.
  }
  return $x;
}

sub xml_escape {  # not destructive
  my $x;
  return '' unless defined($x = $_[0]);
  if($HIGH_BIT_OK) {
    $x =~ s/([&<>])/$Char2xmlent{ord $1} or "&#".ord($1).";"/eg;
       # Encode '&', and '<' and '>'
  } else {
    $x =~ s/([^\cm\cj\f\t !-%'-;=?-~])/$Char2xmlent{ord $1} or "&#".ord($1).";"/eg;
       # Encode control chars, high bit chars, '&', and '<' and '>'
  }
  return $x;
}

sub xml_attr_escape {  # not destructive
  my $x;
  return '' unless defined($x = $_[0]);

  if($HIGH_BIT_OK) {
    $x =~ s/([&<>"])/$Char2xmlent{ord $1} or "&#".ord($1).";"/eg;
       # Encode '&', '"', and '<' and '>'
  } else {
    $x =~ s/([^\cm\cj\f\t !\#-\%'-;=?-~])/$Char2xmlent{ord $1} or "&#".ord($1).";"/eg;
       # Encode control chars, high bit chars, '"', '&', and '<' and '>'
  }
  return $x;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub sanitize_newlines {   # DESTRUCTIVE
  if("\n" eq "\cm") {
    $_[0] =~ s/\cm?\cj/\n/g;  # turn \cj and \cm\cj into \n
  } elsif("\n" eq "\cj") {
    $_[0] =~ s/\cm\cj/\n/g;  # turn \cm and \cm\cj into \n
  } else {
    $_[0] =~ s/(?:(?:\cm?\cj)|\cm)/\n/g;
      # turn \cm\cj, \cj, or \cm  into \n
  }
  return;
}

###########################################################################
###########################################################################

use vars qw(%Acceptable_children);
{
  # This just recapitulates what's in the DTD:
  my $style  = {map{;$_,1} qw(b   i   c   x   f   s   link)};
  my $pstyle = {'#PCDATA',1, %$style};
  my $pcdata = {'#PCDATA',1};
  %Acceptable_children = (
   'pod'  => {map{;$_,1} qw(head1 head2 head3 head4 p pre list for)},
   map(($_=>$pstyle), qw(head1 head2 head3 head4 p)),
   'pre'  => $pcdata,
   'list' => {map{;$_,1} qw(item p pre list for)},
   'item' => $pstyle,
   'for' => $pcdata,
   map(($_=>$pstyle), qw(link b i c f x s)),
  );
}

sub xml2pod ($) {
  my $content = $_[0];
  require XML::Parser;
  
  my $out;
  my($gi, %attr, $text, $cm_set); # scratch
  
  my(@stack);
  my @paragraph_stack;
    # pop/pushed only by paragraph-containing elements, and link
  my @for_stack;  # kept by 'for' elements
  my @link_stack;   # kept by 'link' elements
  my $xml = XML::Parser->new( 'Handlers' => {

     ##
    ##
    ## On the way in...
    
    'Start' => sub {
      (undef, $gi, %attr) = @_;
      push @stack, $gi;
      DEBUG > 1 and print ' ', join('.', @stack), "+\n";
      
      if($XML_VALIDATE) {
        if(@stack < 2) {
          unless($gi eq 'pod') {
            # I think XML::Parser would catch this, but anyway.
            die "Can't have a childless \"$gi\" element, in $content";
          }
        } elsif(defined($cm_set = $Acceptable_children{$stack[-2]})) {
          die "Can't have a \"$gi\" in a \"$stack[-2]\", in $content (stack @stack)"
           unless $cm_set->{$gi};
        } else {
          die "Unknown element \"$gi\"";
        }
        # TODO: attribute validation!
      }
      
      if($gi =~ m/^[bicxfs]$/s) {
        $paragraph_stack[-1] .= "\U$gi<";
      } elsif($gi eq 'p' or $gi eq 'pre') {
        push @paragraph_stack, '';
      } elsif($gi eq 'for') {
        $text = $attr{'target'} || '????';
        push @for_stack, $text;
        push @paragraph_stack, '';
      } elsif($gi eq 'list') {
        $text = $attr{'indent'};
        $out .= (defined($text) && length($text))
                 ? "=over $text\n\n" : "=over\n\n";
      } elsif($gi eq 'item') {
        $out .= '=item ';
        push @paragraph_stack, '';
      } elsif($gi =~ m/^head[1234]$/s) {
        push @paragraph_stack, '=' . $gi . ' ';
      } elsif($gi eq 'link') {  # a hack
        push @link_stack, [$attr{'page'}, $attr{'section'}];
        push @paragraph_stack, '';
      } elsif($gi eq 'pod') {
        my $text = $attr{'xmlns'} || $XMLNS;
        die "pod has a foreign namespace: \"$text\" instead of \"$XMLNS\""
         unless $text eq $XMLNS;
      } else {
        DEBUG and print "Opening unknown element \"$gi\"\n";
      }
      return;
    },

     ##
    ##
    ## And on the way out...

    'End'  => sub {
      $gi = $_[1];
      DEBUG > 1 and print ' ', join('.', @stack), "-\n";
      die "INSANE! Stack mismatch!  $text ne $gi"
       unless $gi eq ($text = pop @stack);

      if($gi =~ m/^[bicxfs]$/s) {
        $paragraph_stack[-1] .= ">";
      } elsif($gi eq 'p') {
        # A paragraph must start with non-WS, non-=, and must contain
        #  no \n\n's until its very end.
      
        $text = pop @paragraph_stack;
        $text =~ s/^(\s)/Z<>$1/s;  # make sure we're NOT indented
        $text =~ s/^=/Z<>=/s;  # make sure we're NOT =-initial
        $text =~ s/\n+$//s;  # nix terminal newlines!
        $text =~ s/\n(?=\n)/\n /g;  # separate double-newlines
        unless(length $text) {
          DEBUG and print "Odd, null p-paragraph\n";
          return;
        }
        
        # These don't beautify /everything/ beautifiable, but they try.
        while($text =~ s/([^a-zA-Z<])E<lt>/$1</g) {1}
         # Turn E<gt>'s that obviously don't need escaping, back into <'s
        while($text =~ s/^([^<]*)E<gt>/$1>/) {1}
         # Turn obviously harmless E<gt>'s back into ">"'s.
        
        $text .= "\n\n";
        $out .= $text;
      } elsif($gi eq 'pre') {
        # A verbatim paragraph must start with WS, and must contain
        #  no \n\n's until its very end.

        $text = pop @paragraph_stack;
        $text =~ s/^\n+//s; # nix leading strictly-blank lines
        $text =~ s/^(\S)/ \n$1/s;  # make sure we ARE indented
          # that means we don't have to make sure we don't start with a '='
        $text =~ s/\n+$//s;  # nix terminal newlines!
        $text =~ s/\n(?=\n)/\n /g;  # separate double-newlines
        #$text =~ tr/\0-\xFF//CU if $LATIN_1; # since we can't E<..> things
        unless(length $text) {
          DEBUG and print "Odd, null pre-paragraph\n";
          return;
        }
        $text .= "\n\n";
        $out .= $text;

      } elsif($gi eq 'for') {
        my $kind = pop @for_stack;
        $text = "\n\n=begin $kind\n\n" . pop @paragraph_stack;
        $text =~ s/\n+$//s;  # nix terminal newlines!
        $text =~ s/\n(?=\n)/\n /g;  # separate double-newlines
        $text .= "\n\n=end $kind\n\n";
        $out .= $text;

      } elsif($gi eq 'list') {
        $out .= "=back\n\n";

      } elsif($gi eq 'item') {
        $text = pop @paragraph_stack;
        $text =~ s/^\s*//s;  # kill leading space
        $text =~ s/\n+$//s;  # nix terminal newlines!
        $text =~ s/\n(?=\n)/\n /g;  # separate double-newlines
        $text .= "\n\n";

        # These don't beautify /everything/ beautifiable, but they try.
        while($text =~ s/([^a-zA-Z<])E<lt>/$1</g) {1}
         # Turn E<gt>'s that obviously don't need escaping, back into <'s
        while($text =~ s/^([^<]*)E<gt>/$1>/) {1}
         # Turn obviously harmless E<gt>'s back into ">"'s.

        $out .= $text;

      } elsif($gi =~ m/^head[1234]$/s) {
        $text = pop @paragraph_stack;
        $text =~ s/^(\s)/Z<>$1/s;  # make sure we're NOT (visibly) indented
        $text =~ s/\n+$//s;  # nix terminal newlines!
        $text =~ s/\n(?=\n)/\n /g;  # nix any double-newlines
        $text .= "\n\n";

        # These don't beautify /everything/ beautifiable, but they try.
        while($text =~ s/([^a-zA-Z<])E<lt>/$1</g) {1}
         # Turn E<gt>'s that obviously don't need escaping, back into <'s
        while($text =~ s/^([^<]*)E<gt>/$1>/) {1}
         # Turn obviously harmless E<gt>'s back into ">"'s.

        $out .= $text;
        
      } elsif($gi eq 'link') {  # a hack
        $text = pop @paragraph_stack;
        # "Text cannot contain the characters '/' and '|'"
        $text =~ s/\|/E<124>/g;   # AKA verbar
        $text =~ s{/}{E<47>}g;    # AKA sol
        $text =~ s/\n(?=\n)/\n /g;
          # nix any double-newlines, just for good measure
        $text .= '|' if length $text;
        
        my($xref, $section) = @{pop @link_stack};
        $xref    = '' unless defined $xref;  # "" means 'in this document'
        $section = '' unless defined $section;

        $xref = pod_escape($xref);
        $xref =~ s{/}{E<47>}g;
        $section = pod_escape("/\"$section\"") if length $section;
        
        $section = '/"???"' unless length $xref or length $section;
         # signals aberrant input!
        
        $paragraph_stack[-1] .= "L<$text$xref$section>";

      } elsif($gi eq 'pod') {
        # no-op
      } else {
        DEBUG and print "Closing unknown element \"$gi\"\n";
      }
      return;
    },
    
     ##
    ##
    ## Character data!  MATANGA!!!
    'Char' => sub {
      shift;
      return unless defined $_[0] and length $_[0]; # sanity

      if(!@stack) {
        die "Non-WS text on empty stack: \"$_[0]\""
         unless $_[0] =~ m/^\s+$/s;
      } else {
        if(($Acceptable_children{$stack[-1]}
            || die "Putting text under unknown element \"$stack[-1]\""
        )->{'#PCDATA'}) {
          # This is the only case where we can add:
          die "\@paragraph_stack is empty? (stack: @stack)"
           unless @paragraph_stack;
          if($stack[-1] eq 'pre') {
            $paragraph_stack[-1] .= $_[0];
          } else {
            $paragraph_stack[-1] .= pod_escape($_[0]);
          }
        } else {
          # doesn't allow PCDATA
          die "Can't have non-WS text in a \"$stack[-1]\""
           unless $_[0] =~ m/^\s+$/s;
          # Else it's just ignorable whitespace.
        }
      }

      return;
    },
    
    # 'Comment' => sub { },
    # 'Proc'    => sub { },
    # 'Attlist' => sub { },
    # 'Element' => sub { },
    # 'Doctype' => sub { },
  });

  # Now actually process...
  $out = "";
  if(ref($content) eq 'SCALAR') {
    $xml->parse($$content);
  } else {
    $xml->parsefile($content);
  }
  
  $out =~ s/^([^=])/=pod\n\n$1/;
   # make sure that we start with a =-thingie, one way or another.
  
  $out .= "=cut\n\n";

  sanitize_newlines($out);
  return $out;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

{
  my %e = ('<' => 'E<lt>', '>' => 'E<gt>' );
  sub pod_escape {
    #print STDERR "IN: <$_[0]>\n";
    my $it = $_[0];
    $it =~ s/([^\cm\cj\f\t !-;=?-~])/$Char2podent{ord $1} or "E<".ord($1).">"/eg;
     # Encode control chars, high bit chars and '<' and '>'
    #print STDERR "OUT: <$_[0]>\n\n";
    return $it;
  }
}

###########################################################################
###########################################################################
1;

