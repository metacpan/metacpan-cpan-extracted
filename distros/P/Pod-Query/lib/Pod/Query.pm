package Pod::Query;

use v5.16;
use strict;
use warnings;
use Pod::Text();
use Pod::LOL();
use File::Spec::Functions qw( catfile );
use List::Util            qw( first );
use Text::ParseWords      qw( parse_line );
use Term::Size::Any       qw( chars );

=head1 NAME

Pod::Query - Query pod documents

=head1 VERSION

Version 0.37

=cut

our $VERSION                   = '0.37';
our $DEBUG_LOL_DUMP            = 0;
our $DEBUG_STRUCT_OVER         = 0;
our $DEBUG_TREE                = 0;
our $DEBUG_TREE_DUMP           = 0;
our $DEBUG_FIND_CONDITIONS     = 0;
our $DEBUG_FIND_AFTER_DEFAULTS = 0;
our $DEBUG_PRE_FIND_DUMP       = 0;
our $DEBUG_FIND                = 0;
our $DEBUG_FIND_DUMP           = 0;
our $DEBUG_INVERT              = 0;
our $DEBUG_RENDER              = 0;
our $MOCK_ROOT                 = 0;

=head1 SYNOPSIS

Query POD information from a file

   % perl -MPod::Query -E 'say for Pod::Query->new("ojo")->find("head1[0]")'

   NAME
   ojo - Fun one-liners with Mojo

   % perl -MPod::Query -E 'say Pod::Query->new("ojo")->find("head1[0]/Para[0]")'

   ojo - Fun one-liners with Mojo

   % perl -MPod::Query -E 'say Pod::Query->new(shift)->find("head1[0]/Para[0]")' my.pod

Find Methods:

	find_title;
	find_method;
	find_method_summary;
	find_events;
	find($query_sting);
	find(@query_structs);

=head1 DESCRIPTION

This module takes a class name, extracts the POD
and provides methods to query specific information.

=head1 SUBROUTINES/METHODS

=cut

#
# Method maker
#

=head2 _has

Generates class accessor methods (like Mojo::Base::attr)

=cut

sub _has {
    no strict 'refs';
    for my $attr ( @_ ) {
        *$attr = sub {
            return $_[0]{$attr} if @_ == 1;    # Get: return $self-<{$attr}
            $_[0]{$attr} = $_[1];              # Set: $self->{$attr} = $val
            $_[0];                             # return $self
        };
    }
}

=head2 path

Path to the pod class file

=head2 lol

List of lists (LOL) structure of the pod file.
Result of Pod::LOL.

=head2 tree

An hierarchy is added to the lol to create a
tree like structure of the pod file.

=head2 class_is_path

Flag to indicate if the class is really a path to the file.

=cut

sub import {
    _has qw(
      path
      lol
      tree
      class_is_path
    );
}

#
# Debug
#

sub _dumper {
    require Data::Dumper;
    my $data = Data::Dumper
      ->new( [@_] )
      ->Indent( 1 )
      ->Sortkeys( 1 )
      ->Terse( 1 )
      ->Useqq( 1 )
      ->Dump;
    return $data if defined wantarray;
    say $data;
}

=head2 new

Create a new object.
Return value is cached (based on the class of the pod file).

	use Pod::Query;
	my $pod = Pod::Query->new('Pod::LOL', PATH_ONLY=0);

PATH_ONLY can be used to determine the path to the pod
document without having to do much unnecessary work.

=cut

sub new {
    my ( $class, $pod_class, $path_only ) = @_;
    $path_only //= 0;
    state %CACHE;

    my $cached;
    return $cached if $cached = $CACHE{$pod_class};

    my $s = bless {
        pod_class => $pod_class,
        lol       => [],
        tree      => [],
    }, $class;

    $s->path( $s->_class_to_path( $pod_class ) );

    return $s if $path_only or not $s->path;

    my $lol = $MOCK_ROOT ? _mock_root() : Pod::LOL->new_root( $s->path );
    $lol = _flatten_for_tags( $lol );
    if ( $DEBUG_LOL_DUMP ) {
        say "DEBUG_LOL_DUMP: " . _dumper $lol;
        exit;
    }

    $s->lol( $lol );
    $s->tree( _lol_to_tree( $lol ) );
    if ( $DEBUG_TREE_DUMP ) {
        say "DEBUG_TREE_DUMP: " . _dumper $s->tree();
        exit;
    }

    $CACHE{$pod_class} = $s;

    $s;
}

=head2 _class_to_path

Given a class name, returns the path to the pod file.
Return value is cached (based on the class of the pod file).

If the class is not found in INC, it will be checked whether
the input is an existing file path.

Returns an empty string if there are any errors.

=cut

sub _class_to_path {
    my ( $s, $pod_class ) = @_;
    state %CACHE;
    my $path;

    return $path if $path = $CACHE{$pod_class};

    my $partial_path = catfile( split /::/, $pod_class ) . '.pm';

    # Shortcut for files already used.
    $path = $INC{$partial_path};
    return $CACHE{$pod_class} = $path if $path and -f $path;

    # Otherwise find it ourselves.
    for ( @INC ) {
        $path = catfile( $_, $partial_path );
        return $CACHE{$pod_class} = $path if $path and -f $path;
    }

    # Check for it in PATH also.
    # Maybe pod_class is the path.
    for ( "", split /:/, $ENV{PATH} ) {

        # Absolute path or current folder means class is path.
        $path = ( $_ and $_ ne "." ) ? catfile( $_, $pod_class ) : $pod_class;
        if ( $path and -f $path ) {
            $s->class_is_path( 1 ) if ref $s;
            return $CACHE{$pod_class} = $path;
        }
    }

    return "";
}

=head2 _mock_root

For debugging and/or testing.
Builds a sample object (overwrite this in a test file).

=cut

sub _mock_root { }

=head2 _flatten_for_tags

Removes for tags from the lol and flattens
out the inner tags to be on the same level as the for
tag was.

=cut

sub _flatten_for_tags {
    my ( $lol ) = @_;
    my @flat;

    for ( @$lol ) {
        my ( $tag, @data ) = @$_;
        $tag //= '';

        push @flat, ( $tag eq "for" ) ? @data : $_;
    }

    \@flat;
}

=head2 _lol_to_tree

Generates a tree from a Pod::LOL object.
The structure of the tree is based on the N (level) in "=headN".

This example pod:

   =head1 FUNCTIONS

   =Para  Description of Functions

   =head2 Function1

   =Para  Description of Function1

   =head1 AUTHOR

   =cut

This will be grouped as:

   =head1 FUNCTIONS
      =Para Description of Functions
      =head2 Function1
         =Para Description of Function1
   =head1 AUTHOR

In summary:

=over 2

=item *

Non "head" tags are always grouped "below".

=item *

HeadN tags with a higher N with also be grouped below.

=item *

HeadN tags with the same or lower N will be grouped higher.

=back

=cut

sub _lol_to_tree {
    my ( $lol ) = @_;
    my ( $is_in, $is_out );
    my %heads_table = __PACKAGE__->_define_heads_regex_table();
    my $is_head     = qr/ ^ head (\d) $ /x;
    my $node        = {};
    my @tree;

    my $push = sub {    # push to tree.
        return if not %$node;
        my $kids = $node->{kids};
        $node->{kids} = _lol_to_tree( $kids )
          if ref( $kids ) && first { $_->{tag} =~ /$is_head/ } @$kids;
        push @tree, $node;
        $node = {};
    };

    say "\n_ROOT_TO_TREE()" if $DEBUG_TREE;

    for ( @$lol ) {
        say "\n_=", _dumper $_ if $DEBUG_TREE;

        my $leaf = _make_leaf( $_ );
        say "\nleaf=", _dumper $leaf if $DEBUG_TREE;

        # Outer tag.
        if ( not $is_in or $leaf->{tag} =~ /$is_out/ ) {
            $push->();
            $node = $leaf;
            if ( $leaf->{tag} =~ /$is_head/ ) {
                ( $is_in, $is_out ) = @{$heads_table{$1}};
            }
        }
        else {
            push @{$node->{kids}}, $leaf;
            say "node: ", _dumper $node if $DEBUG_TREE;
        }
    }

    $push->();

    \@tree;
}

=head2 _define_heads_regex_table

Generates the regexes for head elements inside
and outside the current head.

=cut

sub _define_heads_regex_table {
    map {
        my $inner = join "", $_ + 1 .. 5;    # num=2, inner=345
        my $outer = join "", 0 .. $_;        # num=2, outer=012

        $_ => [ map { qr/ ^ head ([$_]) $ /x } $inner, $outer ]
    } 1 .. 4;
}

=head2 _make_leaf

Creates a new node (aka leaf).

=cut

sub _make_leaf {
    my ( $node ) = @_;
    return $node if ref $node eq ref {};

    my ( $tag, @text ) = @$node;
    my $leaf = { tag => $tag };

    if ( $tag =~ / ^ over- /x ) {
        $leaf->{kids} = _structure_over( \@text );
        $leaf->{text} = "";
    }
    else {
        $leaf->{text} = join "", @text;
    }

    $leaf;
}

=head2 _structure_over

Restructures the text for an "over-text" element to be under it.
Also, "item-text" will be the first element of each group.

=cut

sub _structure_over {
    my ( $text_list ) = @_;
    my @struct;
    my @nodes;

    my $push = sub {
        return if not @nodes;

        # First is the parent node.
        my $item_text = shift @nodes;

        # Treat the rest of the tags as kids.
        push @struct,
          { %$item_text, @nodes ? ( kids => [ splice @nodes ] ) : (), };
    };

    for ( @$text_list ) {
        my ( $tag, @text ) = @$_;
        $push->() if $tag =~ / ^ item- /x;
        push @nodes,
          {
            tag  => $tag,
            text => join( "", @text ),
          };
    }

    $push->();

    if ( $DEBUG_STRUCT_OVER ) {
        say "DEBUG_STRUCT_OVER-IN: " . _dumper $text_list;
        say "DEBUG_STRUCT_OVER-OUT: " . _dumper \@struct;
    }

    \@struct;
}

=head2 find_title

Extracts the title information.

=cut

sub find_title {
    my ( $s ) = @_;
    scalar $s->find( 'head1=NAME[0]/Para[0]' );
}

=head2 find_method

Extracts the complete method information.

=cut

sub find_method {
    my ( $s, $method ) = @_;
    my $m = $s->_clean_method_name( $method ) or return "";

    $s->find( sprintf '~head=~^%s\b.*$[0]**', $m );
}

=head2 find_method_summary

Extracts the method summary.

=cut

sub find_method_summary {
    my ( $s, $method ) = @_;
    my $m = $s->_clean_method_name( $method ) or return "";

    scalar $s->find( sprintf '~head=~^%s\b.*$[0]/~(Data|Para)[0]', $m );
}

=head2 _clean_method_name

Returns a method name without any possible parenthesis.

=cut

sub _clean_method_name {
    my ( $s, $name ) = @_;
    my $safe_start = qr/ ^ [\w_] /x;
    my $safe_end   = qr/ [\w_()] $ /x;
    return if $name !~ $safe_start;
    return if $name !~ $safe_end;

    my $clean = quotemeta( $name =~ s/[^a-zA-Z0-9_]+//gr );
    return if $clean !~ $safe_start;

    $clean;
}

=head2 find_events

Extracts a list of events with a description.

Returns a list of key value pairs.

=cut

sub find_events {
    my ( $s ) = @_;
    $s->find( '~head=EVENTS[0]/~head*/(Para)[0]' );
}

=head2 find

Generic extraction command.

Note: This function is Scalar/List context sensitive!

   $query->find($condition)

Where condtion is a string as described in L</"_query_string_to_struct">

   $query->find(@conditions)

Where each condition can contain:

   {
      tag       => "TAG_NAME",    # Find all matching tags.
      text      => "TEXT_NAME",   # Find all matching texts.
      keep      => 1,             # Capture the text.
      keep_all  => 1,             # Capture entire section.
      nth       => 0,             # Use only the nth match.
      nth_in_group => 0,             # Use only the nth matching group.
   }

Return contents of entire head section:

   find (
      {tag => "head", text => "a", keep_all => 1},
   )

Results:

   [
      "  my \$app = a('/hel...",
      {text => "Create a route with ...", wrap => 1},
      "  \$ perl -Mojo -E ...",
   ]

=cut

sub find {
    my ( $s, @raw_conditions ) = @_;

    my $find_conditions;

    # If the find condition is a single string.
    if ( @raw_conditions == 1 and not ref $raw_conditions[0] ) {
        $find_conditions = $s->_query_string_to_struct( $raw_conditions[0] );
    }
    else {
        $find_conditions = \@raw_conditions;
    }
    say "DEBUG_FIND_CONDITIONS: " . _dumper $find_conditions
      if $DEBUG_FIND_CONDITIONS;

    _check_conditions( $find_conditions );
    _set_condition_defaults( $find_conditions );
    say "DEBUG_FIND_AFTER_DEFAULTS " . _dumper $find_conditions
      if $DEBUG_FIND_AFTER_DEFAULTS;

    my @tree = @{$s->tree};
    my $kept_all;
    if ( $DEBUG_PRE_FIND_DUMP ) {
        say "DEBUG_PRE_FIND_DUMP: " . _dumper \@tree;
        exit;
    }

    for ( @$find_conditions ) {
        @tree = _find( $_, @tree );
        if ( $_->{keep_all} ) {
            $kept_all++;
            last;
        }
    }
    if ( $DEBUG_FIND_DUMP ) {
        say "DEBUG_FIND_DUMP: " . _dumper \@tree;
        exit if $DEBUG_FIND_DUMP > 1;
    }

    if ( not $kept_all ) {
        @tree = _invert( @tree );
    }

    _render( $kept_all, @tree );
}

=head2 _query_string_to_struct

Convert a pod query string into a structure based on these rules:

   1. Split string by '/'.
      Each piece is a separate list of conditions.

   2. Remove an optional '*' or '**' from the last condition.
      Keep is set if we have '*'.
      Keep all is set if we have '**'.

   3. Remove an optional [N] from the last condition.
      (Where N is a decimal).
      Set nth base on 'N'.
      Set nth_in_group if previous word is surrounded by ():
         (WORD)[N]

   4. Double and single quotes are removed from the ends (if matching).

   5. Split each list of conditions by "=".
      First word is the tag.
      Second word is the text (if any).
      If either starts with a tilde, then the word:
         - is treated like a pattern.
         - is case Insensitive.

   Precedence:
      If quoted and ~, left wins:
      ~"head1" => qr/"head"/,
      "~head1" => qr/head/,

=cut

sub _query_string_to_struct {
    my ( $s, $query_string ) = @_;
    my $is_nth          = qr/ \[ (-?\d+) \] $ /x;
    my $is_nth_in_group = qr/ ^ \( (.+) \) $is_nth /x;
    my $is_keep         = qr/ \* $ /x;
    my $is_keep_all     = qr/ \* \* $ /x;

    my @query_struct =
      map {
        my @condition = parse_line( '=', "1", $_ );
        my $set       = {};

        # Set flags based on last condition.
        for ( $condition[-1] ) {
            if ( s/$is_keep_all// ) {
                $set->{keep_all}++;
            }
            elsif ( s/$is_keep// ) {
                $set->{keep}++;
            }

            if ( s/$is_nth_in_group// ) {
                $_ = $1;
                $set->{nth_in_group} = $2;
            }
            elsif ( s/$is_nth// ) {
                $set->{nth} = $1;
            }
        }

        # Remove outer quotes (if any).
        for ( @condition ) {
            for my $quote ( qw/ " ' / ) {
                if (    $quote eq substr( $_, 0, 1 )
                    and $quote eq substr( $_, -1 ) )
                {
                    $_ = substr( $_, 1, -1 ); # Strip first and last characters.
                    last;                     # Skip multi quoting.
                }
            }
        }

        # Regex or literal.
        for ( qw/ tag text / ) {
            last if not @condition;
            my $cond = shift @condition;
            $set->{$_} = ( $cond =~ s/^~// ) ? qr/$cond/i : $cond;
        }

        $set;
      }
      grep { $_ }    # Skip trailing and leading slashes.
      parse_line( '/', 1, $query_string );

    \@query_struct;
}

=head2 _check_conditions

Check if queries are valid.

=cut

sub _check_conditions {
    my ( $sections ) = @_;

    my $error_message = <<'ERROR';

    Invalid input: expecting a hash reference!

    Syntax:

        $pod->find( 'QUERY' )         # As explained in _query_string_to_struct().

        # OR:

        $pod->find(
            # section1
            {
                tag          => "TAG",  # Search to look for.
                text         => "TEXT", # Text of the tag to find.
                keep         => 1,      # Must only be in last section.
                keep_all     => 1,      # Keep this tag and sub tags.
                nth          => 0,      # Stop searching after find so many matches.
                nth_in_group => 0,      # Nth only in the current group.
            },
            # ...
            # conditionN
        );
ERROR

    die "$error_message"
      if not $sections
      or not @$sections
      or grep { ref() ne ref {} } @$sections;

    # keep_all should only be in the last section
    my $last = $#$sections;
    while ( my ( $n, $section ) = each @$sections ) {
        die "Error: keep_all is not in last query!\n"
          if $section->{keep_all} and $n < $last;
    }

  # Cannot use both nth and nth_in_group (makes no sense, plus may cause errors)
    while ( my ( $n, $section ) = each @$sections ) {
        die "Error: nth and nth_in_group are exclusive!\n"
          if defined $section->{nth}
          and defined $section->{nth_in_group};
    }
}

=head2 _set_condition_defaults

Assigns default query options.

=cut

sub _set_condition_defaults {
    my ( $conditions ) = @_;
    for my $condition ( @$conditions ) {

        # Text Options
        for ( qw/ tag text / ) {
            if ( defined $condition->{$_} ) {
                if ( ref $condition->{$_} ne ref qr// ) {
                    $condition->{$_} = qr/^$condition->{$_}$/;
                }
            }
            else {
                $condition->{$_} = qr//;
            }
        }

        # Bit Options
        for ( qw/ keep keep_all / ) {
            if ( defined $condition->{$_} ) {
                $condition->{$_} = !!$condition->{$_};
            }
            else {
                $condition->{$_} = 0;
            }
        }

        # Range Options
        my $is_digit = qr/ ^ -?\d+ $ /x;
        for ( qw/ nth nth_in_group / ) {
            my $v = $condition->{$_};
            if ( defined $v and $v =~ /$is_digit/ ) {
                $v ||= "0 but true";
                my $end  = ( $v >= 0 ) ? "pos" : "neg";    # Set negative or
                my $name = "_${_}_$end";                   # positive form.
                $condition->{$name} = $v;
            }
        }

    }

    # Last condition should be keep or keep_all.
    # (otherwise, why even query for it?)
    for ( $conditions->[-1] ) {
        if ( not $_->{keep} || $_->{keep_all} ) {
            $_->{keep} = 1;
        }
    }
}

=head2 _find

Lower level find command.

=cut

sub _find {
    my ( $need, @groups ) = @_;
    if ( $DEBUG_FIND ) {
        say "\n_FIND()";
        say "need:   ", _dumper $need;
        say "groups: ", _dumper \@groups;
    }

    my $nth_p          = $need->{_nth_pos};      # Simplify code by already
    my $nth_n          = $need->{_nth_neg};      # knowing if neg or pos.
    my $nth_in_group_p = $need->{_nth_grou_pos}; # Set in _set_section_defaults.
    my $nth_in_group_n = $need->{_nth_grou_neg};
    my @found;

  GROUP:
    for my $group ( @groups ) {
        my @tries = ( $group );                # Assume single group to process.
        my @prev  = @{ $group->{prev} // [] };
        my $locked_prev = 0;
        my @found_in_group;
        if ( $DEBUG_FIND ) {
            say "\nprev: ", _dumper \@prev;
            say "group:  ", _dumper $group;
        }

      TRY:
        while ( my $try = shift @tries ) { # Can add to this queue if a sub tag.
            say "\nTrying: try=", _dumper $try if $DEBUG_FIND;

            if ( defined $try->{text} ) {   # over-text has no text (only kids).
                if ( $DEBUG_FIND ) {
                    say "text=$try->{text}";
                    say "next->{tag}=$need->{tag}";
                    say "next->{text}=$need->{text}";
                }

                elsif (
                        $try->{tag}  =~ /$need->{tag}/
                    and $try->{text} =~ /$need->{text}/
                    and not defined $try->{keep} # Already found the node.
                                                 # Since nodes are checked again
                                                 # on next call to _find.
                  )
                {
                    say "Found:  tag=$try->{tag}, text=$try->{text}"
                      if $DEBUG_FIND;
                    push @found_in_group, {
                        %$try,             # Copy current search options.
                        prev => \@prev,    # Need this for the inversion step.
                        keep => $need->{keep},    # Remember for later.
                    };

                    # Specific match (positive)
                    say "nth_p:$nth_p and found_in_group:"
                      . _dumper \@found_in_group
                      if $DEBUG_FIND;
                    if ( $nth_p and @found + @found_in_group > $nth_p ) {
                        say "ENFORCING: nth=$nth_p" if $DEBUG_FIND;
                        @found = $found_in_group[-1];
                        last GROUP;
                    }

                    # Specific group match (positive)
                    elsif ( $nth_in_group_p
                        and @found_in_group > $nth_in_group_p )
                    {
                        say "ENFORCING: nth_in_group=$nth_in_group_p"
                          if $DEBUG_FIND;
                        @found_in_group = $found_in_group[-1];
                        last TRY;
                    }

                    next TRY;
                }
            }

            if ( $try->{kids} and not @found_in_group ) {
                say "Got kids and nothing yet in queue" if $DEBUG_FIND;
                unshift @tries, @{$try->{kids}};    # Process kids tags.
                if ( $try->{keep} and not $locked_prev++ ) {
                    unshift @prev,
                        {
                            map { $_ => $try->{$_} }
                            qw/tag text keep/
                        };
                    say "prev changed: ", _dumper \@prev if $DEBUG_FIND;
                }
                say "locked_prev: $locked_prev" if $DEBUG_FIND;
            }
        }

        # Specific group match (negative)
        if ( $nth_in_group_n and @found_in_group >= abs $nth_in_group_n ) {
            say "ENFORCING: nth_in_group_n=$nth_in_group_n" if $DEBUG_FIND;
            @found_in_group = $found_in_group[$nth_in_group_n];
        }

        push @found, splice @found_in_group if @found_in_group;
    }

    # Specific match (negative)
    if ( $nth_n and @found >= abs $nth_n ) {
        say "ENFORCING: nth=$nth_n" if $DEBUG_FIND;
        @found = $found[$nth_n];
    }

    say "found: ", _dumper \@found if $DEBUG_FIND;

    @found;
}

=head2 _invert

Previous elements are inside of the child
(due to the way the tree is created).

This method walks through each child and puts
the parent in its place.

=cut

sub _invert {
    my ( @groups ) = @_;
    if ( $DEBUG_INVERT ) {
        say "\n_INVERT()";
        say "groups: ", _dumper \@groups;
    }

    my @tree;
    my %navi;

    for my $group ( @groups ) {
        push @tree, {
            map { $_ => $group->{$_} }
            qw/ tag text keep kids /
        };
        if ( $DEBUG_INVERT ) {
            say "\nInverting: group=", _dumper $group;
            say "tree: ",              _dumper \@tree;
        }

        my $prevs = $group->{prev} // [];
        for my $prev ( @$prevs ) {
            my $prev_node = $navi{$prev};
            if ( $DEBUG_INVERT ) {
                say "prev: ",      _dumper $prev;
                say "prev_node: ", _dumper $prev_node;
            }
            if ( $prev_node ) {
                push @$prev_node, pop @tree;
                if ( $DEBUG_INVERT ) {
                    say "FOUND: prev_node=", _dumper $prev_node;
                }
                last;
            }
            else {
                $prev_node = $navi{$prev} = [ $tree[-1] ];
                $tree[-1] = { %$prev, kids => $prev_node };
                if ( $DEBUG_INVERT ) {
                    say "NEW: prev_node=", _dumper $prev_node;
                }
            }
        }

        say "tree end: ", _dumper \@tree if $DEBUG_INVERT;
    }

    @tree;
}

=head2 _render

Transforms a tree of found nodes in a simple list
or a string depending on context.

Pod::Text formatter is used for C<Para> tags when C<keep_all> is set.

=cut

sub _render {
    my ( $kept_all, @tree ) = @_;
    if ( $DEBUG_RENDER ) {
        say "\n_RENDER()";
        say "tree: ",     _dumper \@tree;
        say "kept_all: ", _dumper $kept_all;
    }

    my $formatter = Pod::Text->new( width => get_term_width(), );
    $formatter->{MARGIN} = 2;

    my @lines;
    my $n;

    for my $group ( @tree ) {
        my @tries = ( $group );
        say "\ngroup:  ", _dumper $group if $DEBUG_RENDER;

        while ( my $try = shift @tries ) {
            say "\nTrying: try=", _dumper $try if $DEBUG_RENDER;

            my $_text = $try->{text};
            say "_text=$_text" if $DEBUG_RENDER;

            if ( $kept_all ) {
                $_text .= ":" if ++$n == 1;    # Only for the first line.
                if ( $try->{tag} eq "Para" ) {
                    say "USING FORMATTER" if $DEBUG_RENDER;
                    $_text = $formatter->reformat( $_text );
                }
                push @lines, $_text, "";
            }
            elsif ( $try->{keep} ) {
                say "keeping" if $DEBUG_RENDER;
                push @lines, $_text;
            }

            if ( $try->{kids} ) {
                unshift @tries, @{$try->{kids}};
                if ( $DEBUG_RENDER ) {
                    say "Got kids";
                    say "tries:  ", _dumper \@tries;
                }
            }
        }
    }

    say "lines: ", _dumper \@lines if $DEBUG_RENDER;

    return @lines if wantarray;
    join "\n", @lines;
}

=head2 get_term_width

Determines, caches and returns the terminal width.

=head3 Error: Unable to get Terminal Size

If terminal width cannot be detected, 80 will be assumed.

=cut

sub get_term_width {
    state $term_width;

    if ( not $term_width ) {
        $term_width = eval { chars() };
        $term_width ||= 80;    # Safe default.
        $term_width--;         # Padding.
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

=head1 CAVEAT

Nothing to report.

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
