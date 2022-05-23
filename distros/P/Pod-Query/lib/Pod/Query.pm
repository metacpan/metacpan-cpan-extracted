package Pod::Query;

use v5.24;    # Postfix defef :)
use strict;
use warnings;
use FindBin qw/ $RealBin /;

# use lib "$RealBin/Pod-LOL/lib";
use Mojo::Base qw/ -base -signatures /;
use Mojo::Util qw/ dumper class_to_path /;
use Mojo::ByteStream qw/ b/;
use Term::ReadKey qw/ GetTerminalSize /;
use Pod::Text();
use Pod::LOL;
use Carp qw/ croak /;

=head1 NAME

Pod::Query - Query pod documents

=head1 VERSION

Version 0.04

=cut

our $VERSION       = '0.04';
our $DEBUG_TREE    = 0;
our $DEBUG_FIND    = 0;
our $DEBUG_INVERT  = 0;
our $DEBUG_RENDER  = 0;
our $MOCK_ROOT     = 0;
our $MOCK_SECTIONS = 0;


has [
   qw/ path lol
     tree
     title
     events
     /
];

=head1 SYNOPSIS

Query POD information from a file

	use Pod::Query;
	my $pod = Pod::Query->new('Pod::LOL');

$pod contains the Pod::LOL object and a tree like:

 "tree" => [
    {
      "sub" => [
        {
          "tag" => "Para",
          "text" => [
            "Pod::LOL - Transform POD into a list of lists"
          ]
        }
      ],
      "tag" => "head1",
      "text" => [
        "NAME"
      ]
    },
    {
      "sub" => [
        {
          "tag" => "Para",
          "text" => [
            "Version 0.01"
          ]
        }
      ],
      "tag" => "head1",
      "text" => [
        "VERSION"
      ]
    },
    ...

Find Methods:

	say $pod->find_title;
	say $pod->find_method;
	say $pod->find_method_summary;
	say $pod->find_events;
	say $pod->find(@queries);

Inline (Debugging)
	perl -IPod-Query/lib -MPod::Query -MMojo::Util=dumper -E "say dumper(Pod::Query->new('Pod::LOL'))"

=head1 DESCRIPTION

This module takes a class name, extracts the POD
and provides methods to query specific information.

=head1 SUBROUTINES/METHODS

=head2 new

Create a new object.

=cut

sub new ( $class, $pod_class, $path_only = 0 ) {
   state %CACHE;

   my $cached;
   return $cached if $cached = $CACHE{$pod_class};

   my $s = bless {
      pod_class => $pod_class,
      path      => _class_to_path( $pod_class ),
   }, $class;

   return $s if $path_only;

   my $lol = do {
      if ( $MOCK_ROOT ) {
         _mock_root();
      }
      else {
         my $parser = Pod::LOL->new;

         # Normally =for and =begin would otherwise be skipped.
         $parser->accept_targets( '*' );

         $parser->parse_file( $s->path )->{root};
      }
   };

   $lol = _flatten_for_tags( $lol );

   $s->lol( $lol );
   $s->tree( _lol_to_tree( $lol ) );

   # say dumper $s;
   # exit;

   $CACHE{$pod_class} = $s;

   $s;
}


=head2 _class_to_path

Given a class name, retuns the path to the pod file.

=cut

sub _class_to_path ( $pod_class ) {
   state %CACHE;
   my $p;

   return $p if $p = $CACHE{$pod_class};

   $p = $INC{ class_to_path( $pod_class ) };
   return $CACHE{$pod_class} = $p if $p;

   $p = qx(perldoc -l $pod_class);
   chomp $p;
   return $CACHE{$pod_class} = $p if $p;

   croak "Missing: pod_class=$pod_class";
}


=head2 _mock_root

For debugging only.
Builds a sample object.

=cut

sub _mock_root {
   [

      [ "head1",    "HEAD1", ],
      [ "head2",    "HEAD2_1", ],
      [ "Verbatim", "HEAD2_1-VERBATIM_1", ],
      [ "Para",     "HEAD2_1-PARA_1" . ( "long" x 20 ), ],
      [ "Verbatim", "HEAD2_1-VERBATIM_2", ],
      [ "Para",     "HEAD2_1-PARA_2", ],
      [ "head2",    "HEAD2_2", ],
      [ "Verbatim", "HEAD2_2-VERBATIM_1", ],
      [ "Para",     "HEAD2_2-PARA_1", ],
      [ "Para",     "OPTS:", ],
      [
         "over-text",
         [ "item-text", "OPT-A", ],
         [ "Verbatim",  "OPT-A => 1", ],
         [ "Para",      "OPT-A DESC", ],
         [ "item-text", "OPT-B", ],
         [ "Verbatim",  "OPT-B => 1", ],
         [ "Para",      "OPT-B DESC", ],
      ],
      [ "Verbatim", "HEAD2_2-VERBATIM_2", ],
      [ "Para",     "HEAD2_2-PARA_2", ],

   ]
}

=head2 _flatten_for_tags

Removes for tags from the lol and flattens
out the inner tags to be on the same level as the for
tag was.

=cut

sub _flatten_for_tags ( $lol ) {
   my @flat;

   for ( @$lol ) {
      my ( $tag, @data ) = @$_;
      $tag //= '';

      push @flat, ( $tag eq "for" ) ? @data : $_;
   }

   \@flat;
}

=head2 _lol_to_tree

Transforms a Pod::LOL object into a structured
tree.

=cut

sub _lol_to_tree ( $lol ) {
   my ( $is_in, $is_out );
   my $is_head = qr/ ^ head (\d) $ /x;
   my @main;
   my $q = {};

   my $push = sub {    # push to main list
      return unless %$q;             # only if queue
      my $sub = $q->{sub};           # sub tags
      my $has = _has_head( $sub );
      $q->{sub} = _lol_to_tree( $sub )
        if $has;    # TODO: rename "sub" to "inside" or "inner".
      push @main, $q;
      $q = {};
   };

   $DEBUG_TREE
     and say "\n_ROOT_TO_TREE()";

   for ( $lol->@* ) {
      $DEBUG_TREE
        and say "\n_=", dumper $_;

      my $leaf = _make_leaf( $_ );
      my $tag  = $leaf->{tag};

      $DEBUG_TREE
        and say "\nleaf=", dumper $leaf;

      if ( not $is_in or $tag =~ /$is_out/ ) {
         $push->();
         $q = $leaf;
         next unless $tag =~ /$is_head/;
         ( $is_in, $is_out ) = _get_heads_regex( $1 );
      }
      else {
         $q->{sub} //= [];
         push $q->{sub}->@*, $leaf;
         $DEBUG_TREE
           and say "q: ", dumper $q;
      }
   }

   $push->();

   \@main;
}


=head2 _has_head

Check if the node has sub heads.

=cut

sub _has_head ( $list ) {
   return unless ref $list;

   $DEBUG_TREE
     and say "\nlist=", dumper $list;

   my $is_head = qr/ ^ head (\d) $ /x;

   my $any_head = grep { $_->{tag} =~ /$is_head/; } @$list;

   $any_head;
}


=head2 _make_leaf

Creates a new node (aka leaf).

=cut

sub _make_leaf ( $node ) {
   return $node if ref $node eq ref {};

   my ( $tag, @text ) = @$node;
   my $leaf = {
      tag  => $tag,
      text => \@text,
   };

   if ( $tag eq "over-text" ) {
      $leaf->{is_over} = 1, $leaf->{text} = _structure_over( \@text ),;
   }

   $leaf;
}


=head2 _structure_over

Restructures the text for an "over-text" element.

=cut

sub _structure_over ( $text_list ) {
   my @struct;
   my @q;

   for ( @$text_list ) {
      my ( $tag, $text ) = @$_;
      if ( $tag eq "item-text" ) {
         push @struct, [ splice @q ] if @q;
      }

      push @q, $_;
   }

   push @struct, [ splice @q ] if @q;

   \@struct;
}


=head2 find_title

Extracts the title information.

=cut

sub find_title ( $s ) {
   scalar $s->find(
      {
         tag  => "head1",
         text => "NAME",
         nth  => 0,
      },
      {
         tag => "Para",
         nth => 0,
      },
   );
}


=head2 find_method

Extracts the complete method information.

=cut

sub find_method ( $s, $method ) {
   $s->find(
      {
         tag       => qr/ ^ head \d $ /x,
         text      => quotemeta( $method ) . $s->_is_function_call,
         nth_group => 0,
         keep_all  => 1,
      },
   );
}


=head2 find_method_summary

Extracts the method summary.

=cut

sub find_method_summary ( $s, $method ) {
   scalar $s->find(
      {
         tag  => qr/ ^ head \d $ /x,
         text => quotemeta( $method ) . $s->_is_function_call,
         nth  => 0,
      },
      {
         tag => qr/ (?: Data | Para ) /x,
         nth => 0,
      },
   );
}


=head2 _is_function_call

Regex for function call parenthesis.

=cut

sub _is_function_call {

   # Optional "()".
   qr/ (?:
         \( [^()]* \)
      )?
   /x;
}


=head2 find_events

Extracts a list of events with a description.

Returns a list of key value pairs.

=cut

sub find_events ( $s ) {
   $s->find(
      {
         tag  => qr/ ^ head \d $ /x,
         text => "EVENTS",
         nth  => 0,
      },
      {
         tag  => qr/ ^ head \d $ /x,
         keep => 1,
      },
      {
         tag       => "Para",
         nth_group => 0,
      },
   );
}


=head2 find

Generic extraction command.

context sensitive!

   $pod->find(@sections)

   Where each section can contain:
   {
      tag      => "TAG_NAME",     # Find all matching tags.
      text     => "TEXT_NAME",    # Find all matching texts.
      keep     => 1,              # Capture the text.
      keep_all => 1,              # Capture entire section.
      nth      => 0,              # Use only the nth match.
   }

   # Return contents of entire head section:
   find (
      {tag => "head", text => "a", keep_all => 1},
   )

   # Results:
   # [
   #    "  my \$app = a('/hel...",
   #    {text => "Create a route with ...", wrap => 1},
   #    "  \$ perl -Mojo -E ...",
   # ]

=cut

sub find ( $s, @find_sections ) {
   @find_sections = (

      # {
      #    tag      => "Para",
      #    text     => "SKIP1",
      #    keep     => 1,
      #    keep_all => 1,
      #    nth      => 1,
      # },
   ) if $MOCK_SECTIONS;

   _check_sections( \@find_sections );
   _set_section_defaults( \@find_sections );

   my @tree = $s->tree->@*;
   my $kept_all;

   for my $find ( @find_sections ) {
      @tree = _find( $find, @tree );
      if ( $find->{keep_all} ) {
         $kept_all++;
         last;
      }
   }

   if ( not $kept_all ) {
      @tree = _invert( @tree );
   }

   # say "tree= ", dumper \@tree;
   # exit;

   _render( $kept_all, @tree );
}


=head2 _check_sections

Check if queries are valid.

=cut

sub _check_sections ( $sections ) {

   my $error_message = <<~'ERROR';

      Invalid input: expecting a hash reference!

      Syntax:

         $pod->find(
            # section1
            {
               tag       => "TAG",
               text      => "TEXT",
               keep      => 1,      # Must only be in last section.
               keep_all  => 1,
               nth       => 0,      # These options ...
               nth_group => 0,      #   are exclusive.
            },
            # ...
            # sectionN
         );
   ERROR

   die "$error_message" if grep { ref() ne ref {} } @$sections;

   # keep_all should only be in the last section
   my $last = $#$sections;
   while ( my ( $n, $section ) = each @$sections ) {
      die "Error: keep_all is not in last query!\n"
        if $section->{keep_all} and $n < $last;
   }

   # Cannot use both nth and nth_group (makes no sense, plus may cause errors)
   while ( my ( $n, $section ) = each @$sections ) {
      die "Error: nth and nth_group are exclusive!\n"
        if defined $section->{nth}
        and defined $section->{nth_group};
   }
}


=head2 _set_section_defaults

Assigns default query options.

=cut

sub _set_section_defaults ( $sections ) {
   for my $section ( @$sections ) {

      # Text Options
      for ( qw/ tag text / ) {
         if ( defined $section->{$_} ) {
            if ( ref $section->{$_} ne ref qr// ) {
               $section->{$_} = qr/ ^ $section->{$_} $ /x;
            }
         }
         else {
            $section->{$_} = qr/./;
         }
      }

      # Bit Options
      for ( qw/ keep keep_all / ) {
         if ( defined $section->{$_} ) {
            $section->{$_} = !!$section->{$_};
         }
         else {
            $section->{$_} = 0;
         }
      }

      # Range Options
      my $zero     = "0 but true";
      my $is_digit = qr/ ^ -?\d+ $ /x;
      for ( qw/ nth nth_group / ) {
         my $v = $section->{$_};
         if ( defined $v and $v =~ /$is_digit/ ) {
            $v ||= $zero;
            my $end  = ( $v >= 0 ) ? "pos" : "neg";
            my $name = "_${_}_$end";
            $section->{$name} = $v;
         }
      }

   }
}


=head2 _get_heads_regex

Generates the regexes for head elements inside
and outside the current head.

=cut

sub _get_heads_regex ( $num ) {

   # Make regex for inner and outer =head tags
   my $inner  = join "", grep { $_ > $num } 0 .. 5;
   my $outer  = join "", grep { $_ <= $num } 0 .. 5;
   my $is_in  = qr/ ^ head ([$inner]) $ /x;
   my $is_out = qr/ ^ head ([$outer]) $ /x;

   ( $is_in, $is_out );
}


=head2 _find

Lower level find command.

=cut

sub _find ( $need, @groups ) {
   if ( $DEBUG_FIND ) {
      say "\n_FIND()";
      say "need:   ", dumper $need;
      say "groups: ", dumper \@groups;
   }

   my $tag         = $need->{tag};
   my $text        = $need->{text};
   my $keep        = $need->{keep};
   my $nth         = $need->{nth};
   my $nth_p       = $need->{_nth_pos};
   my $nth_n       = $need->{_nth_neg};
   my $nth_group   = $need->{nth_group};
   my $nth_group_p = $need->{_nth_grou_pos};
   my $nth_group_n = $need->{_nth_grou_neg};
   my @found;

 GROUP: for my $group ( @groups ) {
      my @tries = ( $group );
      my $prev  = $group->{prev} // [];
      $prev = [@$prev];    # shallow copy
      my $locked_prev = 0;
      my @q;
      if ( $DEBUG_FIND ) {
         say "\nprev: ", dumper $prev;
         say "group:  ", dumper $group;
      }

      while ( my $try = shift @tries ) {
         $DEBUG_FIND
           and say "\nTrying: try=", dumper $try;

         my $_tag      = $try->{tag};
         my ( $_text ) = $try->{text}->@*;
         my $_sub      = $try->{sub};
         my $_keep     = $try->{keep};

         if ( defined $_keep ) {
            $DEBUG_FIND
              and say "ENFORCING: keep";
         }
         elsif ($_tag =~ /$tag/
            and $_text =~ /$text/ )
         {
            $DEBUG_FIND
              and say "Found:  tag=$_tag, text=$_text";
            push @q,
              {
               %$try,
               prev => $prev,
               keep => $keep,
              };

            # Specific match (positive)
            if ( $nth_p and @q > $nth_p ) {
               $DEBUG_FIND
                 and say "ENFORCING: nth=$nth";
               @found = $q[$nth_p];
               last GROUP;
            }

            # Specific group match (positive)
            elsif ( $nth_group_p and @q > $nth_group_p ) {
               $DEBUG_FIND
                 and say "ENFORCING: nth_group=$nth_group";
               @q = $q[$nth_group_p];
               last;
            }
         }

         if ( $_sub and not @q ) {
            $DEBUG_FIND
              and say "Got sub and nothing yet in queue";
            unshift @tries, @$_sub;
            if ( $_keep and not $locked_prev++ ) {
               unshift @$prev,
                 {
                  tag  => $_tag,
                  text => [$_text],
                 };
               $DEBUG_FIND
                 and say "prev changed: ", dumper $prev;
            }
            $DEBUG_FIND
              and say "locked_prev: $locked_prev";
         }
      }

      # Specific group match (negative)
      if ( $nth_group_n and @q >= abs $nth_group_n ) {
         $DEBUG_FIND
           and say "ENFORCING: nth_group_n=$nth_group_n";
         @q = $q[$nth_group_n];
      }

      push @found, splice @q if @q;
   }

   # Specific match (negative)
   if ( $nth_n and @found >= abs $nth_n ) {
      $DEBUG_FIND
        and say "ENFORCING: nth=$nth";
      @found = $found[$nth_n];
   }

   $DEBUG_FIND
     and say "found: ", dumper \@found;
   @found;
}


=head2 _to_list

NOT USED

Converts a tree to a plain list.

=cut

sub _to_list ( $groups, $recursive = 0 ) {
   my @groups = @$groups;
   my @list;

   say "\n_TO_LIST()";
   say "groups: ", dumper \@groups;

   while ( my $group = shift @groups ) {
      my ( $tag, $text, $sub, $opts ) = @$group;
      push @list,
        {
         tag  => $tag,
         text => $text,
        };

      if ( $sub and $recursive ) {
         unshift @groups, @$sub;
      }
   }

   @list;
}


=head2 _invert

Previous elements are inside of the child
(due to the way the tree is created).

This method walks through each child and puts
the parent in its place.

=cut

sub _invert ( @groups ) {
   if ( $DEBUG_INVERT ) {
      say "\n_INVERT()";
      say "groups: ", dumper \@groups;
   }

   my @tree;
   my %navi;

   for my $group ( @groups ) {
      push @tree, { %$group{qw/tag text sub is_over/} };
      if ( $DEBUG_INVERT ) {
         say "\nInverting: group=", dumper $group;
         say "tree: ",              dumper \@tree;
      }

      my $prevs = $group->{prev} // [];
      for my $prev ( @$prevs ) {
         my $prev_node = $navi{$prev};
         if ( $DEBUG_INVERT ) {
            say "prev: ",      dumper $prev;
            say "prev_node: ", dumper $prev_node;
         }
         if ( $prev_node ) {
            push @$prev_node, pop @tree;
            if ( $DEBUG_INVERT ) {
               say "FOUND: prev_node=", dumper $prev_node;
            }
            last;
         }
         else {
            $prev_node = $navi{$prev} = [ $tree[-1] ];
            $tree[-1] = { %$prev, sub => $prev_node };
            if ( $DEBUG_INVERT ) {
               say "NEW: prev_node=", dumper $prev_node;
            }
         }
      }

      $DEBUG_INVERT
        and say "tree end: ", dumper \@tree;
   }

   @tree;
}


=head2 _render

Transforms a tree of found nodes in a simple list
or a string depending on context.

=cut

sub _render ( $kept_all, @tree ) {
   if ( $DEBUG_RENDER ) {
      say "\n_RENDER()";
      say "tree: ",     dumper \@tree;
      say "kept_all: ", dumper $kept_all;
   }

   my $formatter = Pod::Text->new( width => get_term_width(), );
   $formatter->{MARGIN} = 2;

   my @lines;
   my $n;

   for my $group ( @tree ) {
      my @tries = ( $group );
      $DEBUG_RENDER
        and say "\ngroup:  ", dumper $group;

      while ( my $try = shift @tries ) {
         $DEBUG_RENDER
           and say "\nTrying: try=", dumper $try;

         my $_tag  = $try->{tag};
         my $_text = $try->{text}[0];
         my $_sub  = $try->{sub};

         if ( $try->{is_over} ) {
            $_text = _render_over( $try->{text}, $kept_all, );
         }
         elsif ( $kept_all ) {
            $_text .= ":" if ++$n == 1;
            if ( $_tag eq "Para" ) {
               $DEBUG_RENDER
                 and say "USING FORMATTER";
               $_text = $formatter->reformat( $_text );
            }
         }

         push @lines, $_text;
         push @lines, "" if $kept_all;

         if ( $_sub ) {
            unshift @tries, @$_sub;
            if ( $DEBUG_RENDER ) {
               say "Got subs";
               say "tries:  ", dumper \@tries;
            }
         }

      }

   }

   $DEBUG_RENDER
     and say "lines: ", dumper \@lines;

   return @lines if wantarray;
   join "\n", @lines;
}


=head2 _render_over

Specifically called for rendering "over" elements.

=cut

sub _render_over ( $list, $kept_all ) {
   if ( $DEBUG_RENDER ) {
      say "\n_RENDER_OVER()";
      say "list=", dumper $list;
   }

   my @txt;

   # Formatters
   state $f_norm;
   state $f_sub;
   if ( not $f_norm ) {
      $f_norm           = Pod::Text->new( width => get_term_width(), );
      $f_norm->{MARGIN} = 2;
      $f_sub            = Pod::Text->new( width => get_term_width(), );
      $f_sub->{MARGIN}  = 4;
   }

   for my $items ( @$list ) {
      my $n;
      for ( @$items ) {
         $DEBUG_RENDER
           and say "over-item=", dumper $_;

         my ( $tag, $text ) = @$_;

         if ( $kept_all ) {
            $DEBUG_RENDER
              and say "USING FORMATTER";
            $text .= ":" if ++$n == 1;
            if ( $tag eq "item-text" ) {
               $text = $f_norm->reformat( $text );
            }
            else {
               $text = b( $text )->trim;
               $text = $f_sub->reformat( $text );
            }
         }

         push @txt, $text;
         push @txt, "" if $kept_all;
      }
   }

   my $new_text = join "\n", @txt;

   $DEBUG_RENDER
     and say "Changed over-text to: $new_text";

   $new_text;
}


=head2 get_term_width

Caches and returns the terminal width.

=cut


sub get_term_width {
   state $term_width;

   if ( not $term_width ) {
      ( $term_width ) = GetTerminalSize();
      $term_width--;
   }

   $term_width;
}


=head1 SEE ALSO

L<App::Pod>

L<Pod::LOL>

L<Pod::Text>


=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/poti1/pod-query/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Query


You can also look for information at:

L<https://metacpan.org/pod/Pod::Query>
L<https://github.com/poti1/pod-query>


=head1 ACKNOWLEDGEMENTS

TBD

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Pod::Query
