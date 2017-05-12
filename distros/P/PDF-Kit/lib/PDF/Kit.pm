#!/
# --------------------------------------
#
#   Title: PDF Kit
# Purpose: A collection of subroutines for PDF::API2.
#
#    Name: PDF::Kit
#    File: Kit.pm
# Created: June  2, 2009
#
# Copyright: Copyright 2009 by Shawn H. Corey.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# --------------------------------------
# Package
package PDF::Kit;

# --------------------------------------
# Pragmas

use strict;
use warnings;

# --------------------------------------
# Version
use version; our $VERSION = qv(v1.0.5);

# --------------------------------------
# Exports
use base qw( Exporter );
our @EXPORT = qw(
  in2pts
  cm2pts
  mm2pts
  baselines
  column_blocks
  small_caps
  flatten
  as_text
  format_paragraph
  align_lines
  justify_lines
  print_lines
  print_paragraph
);
our @EXPORT_OK = qw(
  add_fonts
);
our %EXPORT_TAGS = (
  all => [ @EXPORT, @EXPORT_OK ],
);

# --------------------------------------
# Modules
use Carp;
use Data::Dumper;
use English qw( -no_match_vars ) ;  # Avoids regex performance penalty
use File::Basename;
use POSIX;

# --------------------------------------
# Configuration Parameters

my $SPACE = "\x20";

# Make Data::Dumper pretty
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Maxdepth = 0;

# --------------------------------------
# Variables

# --------------------------------------
# Subroutines

# --------------------------------------
#       Name: in2pts
#      Usage: @points = in2pts( @inches );
#             $points = in2pts( @inches );
#    Purpose: Convert inches to points.
# Parameters: @inches -- List of numbers in inches.
#    Returns: $points -- Single value in points.
#             @points -- List of values in points.
#
sub in2pts {
  my @points = @_;

  $_ *= 72 for @points;
  return wantarray ? @points : $points[0];
}

# --------------------------------------
#       Name: cm2pts
#      Usage: @points = cm2pts( @cm );
#             $points = cm2pts( @cm );
#    Purpose: Convert centimetres to points.
# Parameters:     @cm -- List of numbers in centimetres.
#    Returns: $points -- Single value in points.
#             @points -- List of values in points.
#
sub cm2pts {
  my @points = @_;

  $_ *= 72/2.54 for @points;
  return wantarray ? @points : $points[0];
}

# --------------------------------------
#       Name: mm2pts
#      Usage: @points = mm2pts( @mm );
#             $points = mm2pts( @mm );
#    Purpose: Convert millimetres to points.
# Parameters:     @mm -- List of numbers in millimetres.
#    Returns: $points -- Single value in points.
#             @points -- List of values in points.
#
sub mm2pts {
  my @points = @_;

  $_ *= 72/25.4 for @points;
  return wantarray ? @points : $points[0];
}

# --------------------------------------
#       Name: baselines
#      Usage: @y_values = baselines( $height, $size; $spacing, $bottom );
#    Purpose: Compute the Y values for the baselines.
# Parameters:   $height -- The height of the box.
#                 $size -- Size of the font.
#              $spacing -- Optional line spacing.  Typical values are 1.0, 1.5, 2.0.  Default is 1.0.
#               $bottom -- Optional bottom margin; will be added to the Y values.
#    Returns: @y_values -- List of Y values.
#
sub baselines {
  my $height   = shift @_;
  my $size     = shift @_;
  my $spacing  = shift @_ || 1;
  my $bottom   = shift @_ || 0;
  my $leading  = $size * $spacing;

  my @y_values = ();
  my $y = $height - $size;
  while( $y >= 0 ){
    push @y_values, $y + $bottom;
    $y -= $leading;
  }

  return @y_values;
}

# --------------------------------------
#       Name: column_blocks
#      Usage: \@blocks = column_blocks( \@block, $columns; $gap );
#    Purpose: Calculate the block of the column that fit in the given block
# Parameters:  \@block -- [ min_x, min_y, max_x, max_y ]
#             $columns -- Number of columns
#                 $gap -- Gap between columns; optional, default is 0 (zero).
#    Returns: \@blocks -- List of columns
#
sub column_blocks {
  my $block   = shift @_;
  my $columns = shift @_;
  my $gap     = shift @_ || 0;
  my $blocks  = [];

  my $width = ( $block->[2] - $block->[0] - $gap * ( $columns - 1 ) ) / $columns;

  my $offset = $block->[0];
  for my $i ( 1 .. $columns ){
    push @$blocks, [ @$block ]; # make a copy
    $blocks->[-1][0] = $offset;
    $offset += $width;
    $blocks->[-1][2] = $offset;
    $offset += $gap;
  }

  return $blocks;
}

# --------------------------------------
#       Name: small_caps
#      Usage: \@mut = small_caps( $size, $factor, @text );
#    Purpose: Convert the text to small caps.
# Parameters:   $size -- Size of resulting text.
#             $factor -- The relative size of the lowercase characters.
#                        Recommended factors are from 0.65 to 0.75.
#               @text -- List of text items.
#    Returns:   \@mut -- L<Mark-up Text>.
#
sub small_caps {
  my $size   = shift @_;
  my $factor = shift @_;
  my @text   = @_;
  my $mut    = [];
  my $lc_size = $size * $factor;
  my $prev = '';

  for my $text ( @text ){
    for my $c ( split( //, $text ) ){
      if( isupper( $c ) ){
        if( $prev ne 'u' ){
          push @$mut, { -size=>$size };
          $prev = 'u';
        }
        push @$mut, $c;
      }else{
        if( $prev ne 'l' ){
          push @$mut, { -size=>$lc_size };
          $prev = 'l';
        }
        push @$mut, uc( $c );
      }
    }
  }

  return [ $mut ];
}

# --------------------------------------
#       Name: flatten
#      Usage: \@flattened = flatten( @attributed_text );
#    Purpose: Change nested attributed text into flatten attributed text.
# Parameters: @attributed_text -- nested attributed text
#    Returns:      \@flattened -- flatten attributed text
#
sub flatten {
  my $list = [];
  my @context = (
    {
      -opts => {},
      -items => [ @_ ],
    }
  );

  while( @context ){
    my %opts = %{ $context[-1]{-opts} };
    my $items = $context[-1]{-items};
    pop @context;

    if( @$list && ref( $list->[-1] ) ){
      $list->[-1] = { %opts };
    }else{
      push @$list, { %opts };
    }

    while( @$items ){
      my $item = shift @$items;

      if( my $ref = ref( $item ) ){
        if( $ref eq 'ARRAY' ){
          push @context, {
            -opts => { %opts },
            -items => [ @$items ],
          };
          $items = $item;
        }elsif( $ref eq 'HASH' ){
          @opts{ keys %$item } = values %$item;
          if( @$list && ref( $list->[-1] ) ){
            $list->[-1] = { %opts };
          }else{
            push @$list, { %opts };
          }
        }
      }else{
        unless( @$list && ! ref( $list->[-1] ) ){
          push @$list, '';
        }
        $list->[-1] .= $SPACE if $opts{-space_before};
        $list->[-1] .= $item;
        $list->[-1] .= $SPACE if $opts{-space_after};
      }
    }
  }

  while( @$list && ref( $list->[-1] ) ){
    pop @$list;
  }

  my $flattened = [];
  while( @$list ){
    my %opts = %{ shift @$list };
    delete $opts{-space_before} if exists $opts{-space_before};
    delete $opts{-space_after} if exists $opts{-space_after};
    push @$flattened, [ { %opts }, shift @$list ];
  }

  return $flattened;
}

# --------------------------------------
#       Name: as_text
#      Usage: $text = as_text( @mut );
#    Purpose: Convert nested attributed text to regular text.
# Parameters:   @mut -- List of L<Mark-up Text> items.
#    Returns:  $text -- Its text.
#
sub as_text {
  my $mut   = flatten( @_ );
  my $text  = '';

  for my $item ( @$mut ){
    $text .= $item unless ref( $item );
  }

  return $text;
}

# --------------------------------------
#       Name: format_paragraph
#      Usage: ( \@lines, \@mut ) = format_paragraph( \%paragraph_options, @mut );
#
#    Purpose: Format the L<Mark-up Text> to fit into a paragraph.
#             Items may be text, sub-lists, or mark-up options.
#             Text is broken into words via whitespace, C<m{ \s+ }msx>.
#             Use the UTF character C<\x{a0}> for non-breaking spaces.
#             Leading whitespace in the first text item is ignored.
#
#             Text will formatted with a single space character between each word
#             unless the C<-two_spaces> option is used.
#
#             See POD for more details.
#
#
# Parameters: \%paragraph_options -- Mark-up options for the paragraph.
#                                    See Mark-up Text in the POD for details.
#                            @mut -- Mark-up Text to format.
#    Returns:             \@lines -- A list of formatted lines.
#                           \@mut -- Leftover mut that did not fit into the paragraph.
#                                    These may be used, as is, in another L<format_paragraph()> call.
#
sub format_paragraph {

  # flatten makes things easier
  my $mut = flatten( @_ );

  # remove leading spaces in first text item
  $mut->[1] =~ s{ \A \s+ }{}msx if @$mut > 1;

  # save the indent
  my $indent = 0;
  if( @$mut && exists( $mut->[0][0]{-indent} ) ){
    $indent = $mut->[0][0]{-indent} || 0;
  }

  my $lines = [];
  my $space_pending = 0;
  my $space_width = 0;
  my $trailing_width = 0;
  my $trailing_spaces = '';
  my $two_spaces = 0;

  my $add_p_end = 1;

MUT_LOOP:
  while( @$mut ){
    my %opts = %{ $mut->[0][0] };
    my $text = $mut->[0][1];
    shift @$mut;

    # add a new segment
    if( @$lines ){
      push @{ $lines->[-1]{-segments} }, {
        %opts,
        -offset => $lines->[-1]{-segments}[-1]{-offset} + $lines->[-1]{-segments}[-1]{-length},
        -length => 0,
        -text => '',
      };
    }else{
      push @{ $lines->[0]{-segments} }, {
        %opts,
        -offset => $indent,
        -length => 0,
        -text => '',
      };
    }

    if( $space_pending ){
      $trailing_spaces = $SPACE;
      $trailing_width = $space_width;
      if( $two_spaces ){
        $trailing_spaces .= $SPACE;
        $trailing_width .= $space_width;
      }
    }

    $space_width = &{$opts{-compute_length}}( { %opts, -print=>0, }, $SPACE ); # must redo every time since might have changed from previous

    # process the text
    my @text = split m{ ( \s+ ) }msx, $text;
    while( @text ){
      my $word = shift @text;

      if( $word =~ m{ \A \s }msx ){
        $space_pending = 1;
        next;
      }

      my $word_length = &{$opts{-compute_length}}( { %opts, -print=>0, }, $word );
      my $extended_length = $word_length;
      # a word at end of text may be joined to next
      unless( @text ){
        for my $item ( @$mut ){
          last if $item->[1] =~ m{ \A \s }msx;
          if( $item->[1] =~ m{ \A (\S+) (?=\s) }msx ){
            my $look_ahead = $1;
            $extended_length += &{$opts{-compute_length}}( { %opts, -print=>0, }, $look_ahead );
            last;
          }
          $extended_length += &{$opts{-compute_length}}( { %opts, -print=>0, }, $item->[1] );
        }
      }
      my $right = $lines->[-1]{-segments}[-1]{-offset} + $lines->[-1]{-segments}[-1]{-length} + $extended_length;
      my $new_line = 0;

      if( $trailing_width ){
        if( $trailing_width + $right > $lines->[-1]{-segments}[-1]{-width} ){
          $new_line = 1;
        }
      }elsif( $space_pending ){
        my $spw = $space_width;
        $spw += $space_width if $two_spaces;
        if( $spw + $right > $lines->[-1]{-segments}[-1]{-width} ){
          $new_line = 1;
        }
      }

      # add a new line
      if( $new_line ){
        $lines->[-1]{-width} = $lines->[-1]{-segments}[-1]{-width};
        if( exists( $opts{-max_lines} ) && @$lines >= $opts{-max_lines} ){
          delete $opts{-offset};
          delete $opts{-length};
          delete $opts{-text};
          $opts{-indent} = 0; # everything left over is still part of this paragraph, so it's indent must be zero.
          unshift @$mut, [ { %opts }, join( '', $word, @text ) ];
          $add_p_end = 0;
          last MUT_LOOP;
        }
        push @$lines, {
          -length => 0,
          -segments =>[{
            %opts,
            -offset => 0,
            -length => 0,
            -text => '',
          }],
        };
        $space_pending = 0;
        $trailing_width = 0;
      }

      if( $trailing_width ){
        $lines->[-1]{-length} += $trailing_width;
        $lines->[-1]{-segments}[-1]{-offset} += $trailing_width;
        $lines->[-1]{-segments}[-2]{-length} += $trailing_width;
        $lines->[-1]{-segments}[-2]{-text}   .= $trailing_spaces;
        $trailing_width = 0;
      }elsif( $space_pending ){
        $lines->[-1]{-length} += $space_width;
        $lines->[-1]{-segments}[-1]{-length} += $space_width;
        $lines->[-1]{-segments}[-1]{-text}   .= $SPACE;
        if( $two_spaces ){
          $lines->[-1]{-length} += $space_width;
          $lines->[-1]{-segments}[-1]{-length} += $space_width;
          $lines->[-1]{-segments}[-1]{-text}   .= $SPACE;
        }
      }

      $lines->[-1]{-length} += $word_length;
      $lines->[-1]{-segments}[-1]{-length} += $word_length;
      $lines->[-1]{-segments}[-1]{-text}   .= $word;

      $space_pending = 0;
      $trailing_width = 0;

      # check for two_spaces after word
      $two_spaces = 0;
      if( $opts{-two_spaces} ){
        $two_spaces = $word =~ $opts{-two_spaces} || 0;
      }
    }
  }
  $lines->[-1]{-width} = $lines->[-1]{-segments}[-1]{-width};
  if( @$lines && $add_p_end ){
    $lines->[-1]{-last_line} = 1;
  }

  return ( $lines, $mut );
}

# --------------------------------------
#       Name: align_lines
#      Usage: align_lines( $alignment, $lines );
#    Purpose: Change the offsets in the lines outputted by L<format_paragraph()> to align the paragraph.
# Parameters: $alignment -- A value of 0.0 will left align;
#                           a value of 0.5 will center align;
#                           a value of 1.0 will right align.
#                           Other values will create weird, special effects.
#                 $lines -- Output from L<format_paragraph()>.
#    Returns: none
#
sub align_lines {
  my $alignment = shift @_;
  my $lines     = shift @_;

  # first line may have indent, so do it separate
  my $indent = $lines->[0]{-segments}[0]{-indent} || 0;
  my $gap = $lines->[0]{-width} - $lines->[0]{-length};
  my $offset = $gap * $alignment;
  for my $segment ( @{ $lines->[0]{-segments} } ){
    $segment->{-offset} = $offset;
    $offset += $segment->{-length};
  }

  # do the rest
  for my $line ( @{ $lines }[ 1 .. $#$lines ] ){
    $gap = $line->{-width} - $line->{-length};
    $offset = $gap * $alignment;
    for my $segment ( @{ $line->{-segments} } ){
      $segment->{-offset} = $offset;
      $offset += $segment->{-length};
    }
  }

  return;
}

# --------------------------------------
#       Name: _justify_line
#      Usage: _justify_line( $word_spacing_weight, $character_spacing_weight, $horizontal_scaling_weight, $line; $indent );
#    Purpose: Calculate the amount to adjust the spacing and scaling to justify the line.
# Parameters:       $word_spacing_weight -- How much attributed to spaces between words.
#              $character_spacing_weight -- How much attributed to spaces between characters.
#             $horizontal_scaling_weight -- How much attributed to scaling the glyphs horizontally.
#                                  $line -- The line to adjust.
#                                $indent -- Possible indentation of the line.
#    Returns: none
#
sub _justify_line {
  my $word_spacing_weight       = shift @_;
  my $character_spacing_weight  = shift @_;
  my $horizontal_scaling_weight = shift @_;
  my $line                      = shift @_;
  my $indent                    = shift @_ || 0;

  my $gap = $line->{-width} - $line->{-length} - $indent;

  my $char = 0;
  my $sp   = 0;
  for my $segment ( @{ $line->{-segments} } ){
    $char += length( $segment->{-text} );
    $sp   += $segment->{-text} =~ tr/\x20/\x20/;
  }

  # calculate character spacing
  if( $sp <= 0 ){
    # no spaces if narrow width or non-breaking spaces
    $word_spacing_weight = 0;
    $line->{-wordspace} = 0;

    my $sum = $character_spacing_weight + $horizontal_scaling_weight;
    if( $sum == 0 ){
      $character_spacing_weight  = 0.5;
      $horizontal_scaling_weight = 0.5;
    }else{
      $character_spacing_weight  /= $sum;
      $horizontal_scaling_weight /= $sum;
    }
  }else{
    $line->{-wordspace} = $gap * $word_spacing_weight / $sp;
  }

  # calculate word spacing
  $line->{-charspace} = $gap * $character_spacing_weight / $char;

  # calculate horizontal scaling
  $line->{-hspace} = ( $line->{-width} - $indent ) / ( $line->{-length} + $gap * ( 1 - $horizontal_scaling_weight ) ) * 100;

  # calculate justified offsets
  my $joffset = $indent;
  for my $segment ( @{ $line->{-segments} } ){
    $segment->{-joffset} = $joffset;
    $segment->{-wordspace} = $line->{-wordspace};
    $segment->{-charspace} = $line->{-charspace};
    $segment->{-hspace} = $line->{-hspace};

    $char = length( $segment->{-text} );
    $sp   = $segment->{-text} =~ tr/\x20/\x20/;
    $joffset += $line->{-wordspace} * $sp
              + $line->{-charspace} * $char
              + $line->{-hspace} * $segment->{-length} / 100;
  }

  return;
}

# --------------------------------------
#       Name: justify_lines
#      Usage: justify_lines( $word_spacing_weight, $character_spacing_weight, $horizontal_scaling_weight, $lines );
#    Purpose: Modify the output of format_paragraph() so that the lines are fully justified.
#             See the POD for details.
# Parameters:       $word_spacing_weight -- The weight of the adjustment for word spacing.
#              $character_spacing_weight -- The weight of the adjustment for character spacing.
#             $horizontal_scaling_weight -- The weight of the adjustment for horizontal scaling.
#                                 $lines -- The output of L<format_paragraph()>.
#    Returns: none
#
sub justify_lines {
  my $word_spacing_weight       = abs( shift @_ );
  my $character_spacing_weight  = abs( shift @_ );
  my $horizontal_scaling_weight = abs( shift @_ );
  my $lines                     = shift @_;

  # normalize the weights
  my $sum = $word_spacing_weight + $character_spacing_weight + $horizontal_scaling_weight;
  $word_spacing_weight       /= $sum;
  $character_spacing_weight  /= $sum;
  $horizontal_scaling_weight /= $sum;

  # first line may have an indent, so do it separately
  _justify_line( $word_spacing_weight, $character_spacing_weight, $horizontal_scaling_weight, $lines->[0], $lines->[0]{-segments}[0]{-indent} );

  for my $line ( @{ $lines }[ 1 .. $#$lines ] ){
    # don't do the last line.
    next if $line->{-last_line};

    _justify_line( $word_spacing_weight, $character_spacing_weight, $horizontal_scaling_weight, $line );
  }

  return;
}

# --------------------------------------
#       Name: print_lines
#      Usage: ( \@y_values, $lines ) = print_lines( $left, \@y_values, $lines );
#    Purpose: Print the lines created by L<format_paragraph()>.
# Parameters:      $left -- Left offset for the lines.
#             \@y_values -- A list of baselines for the lines.
#                 $lines -- Formatted lines.
#    Returns: \@y_values -- Left over baselines.
#                 $lines -- Left over lines.
#
sub print_lines {
  my $left     = shift @_;
  my $y_values = shift @_;
  my $lines    = shift @_;

  while( @$y_values && @$lines ){
    my $line = shift @$lines;
    my $y = shift @$y_values;
    for my $segment ( @{ $line->{-segments} } ){
      my %opts = %$segment;
      $opts{-print} = 1;

      my $x = $segment->{-offset};
      if( exists( $segment->{-joffset} ) ){
        $x = $segment->{-joffset};
      }

      $opts{-x} = $x + $left;
      $opts{-y} = $y;
      &{ $segment->{-print_text} }( \%opts, $segment->{-text} );
    }
  }

  return ( $y_values, $lines );
}

# --------------------------------------
#       Name: print_paragraph
#      Usage: ( $bottom, \@mut ) = print_paragraph( \%print_options, \%paragraph_options, @mut );
#    Purpose: Print the paragraph.
#             This subroutine uses L<format_paragraph()> to format the paragraph
#             and then determines where each segment of text should go.
#             It uses the application specified print routine to print it.
#
#             See the POD for details.
#
# Parameters:     \%print_options -- See the POD for details.
#             \%paragraph_options -- Mark-up Text for the paragraph.
#                                    Same as format_paragraph().
#                            @mut -- A list of mut to print with L<Mark-up Text>.
#    Returns:             $bottom -- The bottom of the paragraph.
#                                    Can be used as the top of the next.
#                           \@mut -- A list of mut that did not fit into the paragraph.
#
sub print_paragraph {
  my %opts = ();
  while( @_ && ref( $_[0] ) eq 'HASH' ){
    my %hash = %{ shift @_ };
    @opts{keys %hash} = values %hash;
  }

  my $height = $opts{-block}[3] - $opts{-block}[1];
  my @y_values = baselines( $height, $opts{-size}, ( $opts{-spacing} || 1 ), $opts{-block}[1] );
  my $bottom = $y_values[-1] - $opts{-size} * (( $opts{-spacing} || 1 ) - 1 );

  my $width = $opts{-block}[2] - $opts{-block}[0];
  my ( $lines, $mut ) = format_paragraph( { %opts, -width=>$width, -max_lines=>scalar( @y_values ) }, @_ );

  if( $opts{-justify_word} || $opts{-justify_char} || $opts{-justify_scale} ){
    justify_lines( $opts{-justify_word} || 0, $opts{-justify_char} || 0, $opts{-justify_scale} || 0, $lines );
  }elsif( $opts{-alignment} ){
    align_lines( $opts{-alignment}, $lines );
  }

  my ( $y_values, undef ) = print_lines( $opts{-block}[0], \@y_values, $lines );
  if( @$y_values ){
    $bottom = $y_values->[0] - $opts{-size} * (( $opts{-spacing} || 1 ) - 1 );
  }

  return $bottom, $mut;
}

1;
__DATA__
__END__

=head1 NAME

PDF::Kit - A collection of subroutines for PDF::API2.

=head1 VERSION

This document refers to PDF::Kit version v1.0.5

=head1 SYNOPSIS

  use PDF::Kit;

=head1 DESCRIPTION

A collection of subroutines to be used with L<PDF::API2|PDF::API2>.

=head2 Mark-up Text

Mark-up Text (mut) is a list of items.
If an element is a scalar, it's text to be formatted.
If it's a hash reference, it contains mark-up options that apply to remainder of the current list.
If it's an array reference, it's a sub-list.
For a sub-list, the current mark-up context is preserved and restored after the sub-list is processed.
That way, any mark-up in the sub-list will apply only to the sub-list.

Examples of C<@mut>:

  @mut = ( { size=>12, -space_after=>1, -compute_length=>\&compute_length, },
    'This is plain text.',
    { bold=>1 }, 'This is bold text.',
    { italic=>1 }, 'This is bold-italic text.',
    { bold=>0 }, 'This is italic text.',
    { italic=>0 }, 'This is plain text.',
  );

  @mut = ( { size=>12, -space_after=>1, -compute_length=>\&compute_length, },
    'This is plain text.',
    [ { bold=>1 }, 'This is bold text.' ],
    [ { italic=>1 }, 'This is italic text.' ],
    [ { bold=>1, italic=>1 }, 'This is bold-italic text.' ],
    'This is plain text.',
  );

  @mut = ( { size=>12, -compute_length=>\&compute_length, },
    'This is really ',
    [ { size=>24 }, 'BIG' ],
    '. ',
    "This is not. ",
    [ { typeface=>'sans-serif' }, ":(" ],
  );

You can directly dispatch to the computing subroutine:

  @mut = ( { size=>12, -space_after=>1, },
    { -compute_length=>\&compute_plain, }, 'This is plain text.',
    [ { bold=>1, -compute_length=>\&compute_bold, }, 'This is bold text.' ],
    [ { italic=>1, -compute_length=>\&compute_italic, }, 'This is italic text.' ],
    [ { bold=>1, italic=>1, -compute_length=>\&compute_bolditalic, }, 'This is bold-italic text.' ],
    'This is plain text.',
  );

You can mark-up by tags:

  @mut = ( { size=>12, -space_after=>1, -compute_length=>\&compute_length, },
    'On',
    [{ tag=>'date', epoch=>'-14198400', strftime=>'%B %e, %Y', }, 'July 20, 1969', ],
    'man first walked on the moon.'
  );

=head1 SUBROUTINES

=head2 in2pts

=head3 Usage

  @points = in2pts( @inches );
  $points = in2pts( @inches );

=head3 Purpose

Convert inches to points.

=head3 Parameters

=over 4

=item @inches

List of numbers in inches.

=back

=head3 Returns

=over 4

=item $points

Single value in points.

=item @points

List of values in points.

=back

=head2 cm2pts

=head3 Usage

  @points = cm2pts( @cm );
  $points = cm2pts( @cm );

=head3 Purpose

Convert centimetres to points.

=head3 Parameters

=over 4

=item @cm

List of numbers in centimetres.

=back

=head3 Returns

=over 4

=item $points

Single value in points.

=item @points

List of values in points.

=back

=head2 mm2pts

=head3 Usage

  @points = mm2pts( @mm );
  $points = mm2pts( @mm );

=head3 Purpose

Convert millimetres to points.

=head3 Parameters

=over 4

=item @mm

List of numbers in millimetres.

=back

=head3 Returns

=over 4

=item $points

Single value in points.

=item @points

List of values in points.

=back

=head2 baselines

=head3 Usage

  @y_values = baselines( $height, $size; $spacing, $bottom );

=head3 Purpose

Compute the Y values for the baselines.

=head3 Parameters

=over 4

=item $height

The height of the box.

=item $size

Size of the font.

=item $spacing

Optional line spacing.  Typical values are 1.0, 1.5, 2.0.  Default is 1.0.

=item $bottom

Optional bottom margin; will be added to the Y values.

=back

=head3 Returns

=over 4

=item @y_values

List of Y values.

=back

=head2 column_blocks

=head3 Usage

  \@blocks = column_blocks( \@block, $columns; $gap );

=head3 Purpose

Calculate the block of the column that fit in the given block

=head3 Parameters

=over 4

=item \@block

[ min_x, min_y, max_x, max_y ]

=item $columns

Number of columns

=item $gap

Gap between columns; optional, default is 0 (zero).

=back

=head3 Returns

=over 4

=item \@blocks

List of columns

=back

=head2 small_caps

=head3 Usage

  \@mut = small_caps( $size, $factor, @text );

=head3 Purpose

Convert the text to small caps.

=head3 Parameters

=over 4

=item $size

Size of resulting text.

=item $factor

The relative size of the lowercase characters.
Recommended factors are from 0.65 to 0.75.

=item @text

List of text items.

=back

=head3 Returns

=over 4

=item \@mut

See L<Mark-up Text>.

=back

=head2 flatten

=head3 Usage

  \@flattened = flatten( @attributed_text );

=head3 Purpose

Change nested attributed text into flatten attributed text.

=head3 Parameters

=over 4

=item @attributed_text

nested attributed text

=back

=head3 Returns

=over 4

=item \@flattened

flatten attributed text

=back

=head2 as_text

=head3 Usage

  $text = as_text( @mut );

=head3 Purpose

Convert nested attributed text to regular text.

=head3 Parameters

=over 4

=item @mut

List of L<Mark-up Text> items.

=back

=head3 Returns

=over 4

=item $text

Its text.

=back

=head2 format_paragraph

=head3 Usage

  ( \@lines, \@mut ) = format_paragraph( \%paragraph_options, @mut );

=head3 Purpose

Format the L<Mark-up Text> to fit into a paragraph.
Items may be text, sub-lists, or mark-up options.
Text is broken into words via whitespace, C<m{ \s+ }msx>.
Use the UTF character C<\x{a0}> for non-breaking spaces.
Leading whitespace in the first text item is ignored.

Text will formatted with a single space character between each word
unless the C<-two_spaces> option is used.

=head4 Compute Length Subroutine

B<Usage:>

  $length = compute_length( \%options, $text );

This callback subroutine computes the length of the text string.
The C<\%options> contain all the mark-up options currently in effect.
These can be use to determine how to do the computation.

Also, the following options are set:

=over 4

=item -print

Set to 0 (zero).
By checking this option, the application can use the same subroutine for the L<Print Text Subroutine>.

=back

Note that L</format_paragraph()> reserves all options that start with a minus sign for itself.

=head3 Parameters

=over 4

=item \%paragraph_options

Mark-up options for the paragraph.
See L</Mark-up Text> for details.

Required options are C<-width> and C<-compute_length>.

The C<-indent> option must occur before any text element;
if used, it should be placed here.

All other options may be placed here.

=over 4

=item -width

The width of the paragraph.
This option is required.
If the C<-indent> is greater than the C<-width>, then the first line is blank.
Except for the above, this algorithm places at least one word per line regardless of the C<-width>.
Long words may exceed the paragraph boundaries.

=item -compute_length

This callback subroutine to determine the length of the text.
See L</Compute Length Subroutine> for details.
This option is required.

=item -indent

First line indentation.
If negative, the first line will be to the left of the paragraph boundary.
If greater than C<-width>, the first line will be blank.
Default is 0 (zero).

=item -max_lines

The maximum number of lines to format.
If 0 (zero), then no limit.
Default is 0 (zero).

=item -space_before

If TRUE, treat all text items as though they have leading whitespace.
Default is FALSE.

=item -space_after

If TRUE, treat all text items as though they have trailing whitespace.
Default is FALSE.

=item -two_spaces

A compiled regular expression (see L<perlop/Quote and Quote-like Operators>).
If a word matches, then when formatted it will have two spaces between it and the next text item
(unless it's at the end of a line).

=item I<any>

The application may set any option to communicate with the L<Compute Length Subroutine>.
L</format_paragraph()> reserves options that start with a minus sign for itself.
The application may use any other option name.
It is up to the application to pass sufficient parameters so that the correct calculations can be done.

=back

=back

=over 4

=item @mut

L<Mark-up Text> to format.

=back

=head3 Returns

=over 4

=item \@lines

A list of formatted lines.
Each element of the list is a hash with:

=over 4

=item -length

The total length of the text in the line.
If the C<-indent> was negative, the first line may be greater than the given C<-width>.

=item -width

The width of the line.
Its C<-length> should be less than or equal to this unless C<-indent> is negative and it is the first line.

=item -last_line

Set to 1 (one) if it's the last line of the paragraph.

=item -segments

This is a list of hashes, one for each segment of the line.
Each contain the mark-up for the segment and the following:

=over 4

=item -offset

The offset from the left.  May be negative if the C<-indent> mark-up option was negative.

=item -length

The length of the segment.

=item -text

The text of the segment.

=back

=back

=back

=over 4

=item \@mut

Leftover mut that did not fit into the paragraph.
These may be used, as is, in another L</format_paragraph()> call.

=back

=head2 align_lines

=head3 Usage

  align_lines( $alignment, $lines );

=head3 Purpose

Change the offsets in the lines outputted by L</format_paragraph()> to align the paragraph.

=head3 Parameters

=over 4

=item $alignment

A value of 0.0 will left align;
a value of 0.5 will center align;
a value of 1.0 will right align.
Other values will create weird, special effects.

=item $lines

Output from L</format_paragraph()>.

=back

=head3 Returns

none

=head2 justify_lines

=head3 Usage

  justify_lines( $word_spacing_weight, $character_spacing_weight, $horizontal_scaling_weight, $lines );

=head3 Purpose

Modify the output of L</format_paragraph()> so that the lines are fully justified.

PDF offers three text state parameters to adjust the text so it can be justified.
They are:

=over 4

=item character spacing

See L<PDF Reference/5.2.1 Character Spacing>.

=item word spacing

See L<PDF Reference/5.2.2 Word Spacing>.

=item horizontal scaling

See L<PDF Reference/5.2.3 Horizontal Scaling>.

=back

This subroutine allows you to specify how much of each will be done to achieve justification.
The first three parameters of this subroutine are the weights for each.
The weights will be normalized before they are applied.
Their sum must not be 0 (zero).

If the width of the paragraph is very narrow or the text has non-breaking spaces, C<\xA0>,
then the word spacing may have no effect.
To make justification possible, at least one of the other two weight should be non-zero.

This subroutine adds the following options to the C<$lines>:

=over 4

=item -wordspace

This is the C<$spacing> to be used with L<PDF::API2::Content|PDF::API2::Content>
C<wordspace()> method when printing the line.

=item -charspace

This is the C<$spacing> to be used with L<PDF::API2::Content|PDF::API2::Content>
C<charspace()> method when printing the line.

=item -hspace

This is the C<$spacing> to be used with L<PDF::API2::Content|PDF::API2::Content>
C<hspace()> method when printing the line.

=back

It adds the option C<-joffset> to each segment of C<$lines> which is the offset for justification.

=head3 Parameters

=over 4

=item $word_spacing_weight

The weight of the adjustment for word spacing.

=item $character_spacing_weight

The weight of the adjustment for character spacing.

=item $horizontal_scaling_weight

The weight of the adjustment for horizontal scaling.

=item $lines

The output of L</format_paragraph()>.

=back

=head3 Returns

none

=head2 print_lines

=head3 Usage

  ( \@y_values, $lines ) = print_lines( $left, \@y_values, $lines );

=head3 Purpose

Print the lines created by L</format_paragraph()>.

=head3 Parameters

=over 4

=item $left

Left offset for the lines.

=item \@y_values

A list of baselines for the lines.

=item $lines

Formatted lines.

=back

=head3 Returns

=over 4

=item \@y_values

Left over baselines.

=item $lines

Left over lines.

=back

=head2 print_paragraph

=head3 Usage

  ( $bottom, \@mut ) = print_paragraph( \%print_options, \%paragraph_options, @mut );

=head3 Purpose

Print the paragraph.
This subroutine uses L</format_paragraph()> to format the paragraph
and then determines where each segment of text should go.
It uses the application specified print routine to print it.

=head4 Print Text Subroutine

B<Usage:>

  $length = print_text( \%options, $text );

This callback subroutine prints the text string and returns its length.
The C<\%options> contain all the mark-up options currently in effect.
These can be use to determine how to do the printing.

Also, the following options are set:

=over 4

=item -x

The X coordinate where the text starts.

=item -y

The Y coordinate where the text starts (its baseline).

=item -print

Set to 1 (one).
By checking this option, the application can use the same subroutine for the L<Compute Length Subroutine>.

=back

Note that L</print_paragraph()> reserves all options that start with a minus sign for itself.

=head3 Parameters

=over 4

=item \%print_options

The following options are required:

=over 4

=item -block

The block into which to print: [ left, bottom, right, top ]

=item -print_text

The application specified L<Print Text Subroutine>.

=item -size

The nominal size of the text.
The size multiplied by the C<-spacing> should be greater than or equal to
the largest font size used int the paragraph.

=back

=back

The following options are optional:

=over 4

=over 4

=item -spacing

The line spacing of the paragraph.
Typical values are 1.0, 1.5 and 2.0.
Default is 1.0.
The C<-size> multiplied by the -spacing should be greater than or equal to
the largest font size used int the paragraph.

=item -alignment

How to align the paragraph. A value of 0.0 will left align the paragraph;
a value of 0.5 will center align it;
a value of 1.0 will right align it.

=item -justify_word

The weight of the adjustment for word spacing of justification of the paragraph.

=item -justify_char

The weight of the adjustment for character spacing of justification of the paragraph.

=item -justify_scale

The weight of the adjustment for horizontal scaling of justification of the paragraph.

=item I<any>

The application may set any options to be passed to the Print Text Subroutine.
This subroutine reserves any option that starts with a minus sign for future use.

=back

=back

=over 4

=item \%paragraph_options

L<Mark-up Text> for the paragraph.
The option C<-compute_length>, a subroutine to compute the length of a string, is required.
The C<-width> and C<-max_lines> options will be ignored.

=item @mut

A list of mut to print with L<Mark-up Text>.

=back

=head3 Returns

=over 4

=item $bottom

The bottom of the paragraph.
Can be used as the top of the next.

=item \@mut

A list of mut that did not fit into the paragraph.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head2 Limitations

=over 4

=item *

The word spacing (see L<PDF Reference/5.2.2 Word Spacing>) only applies to the space character, ASCII code C<32>.
If you use non-breaking spaces, ASCII code C<160>, the words will B<NOT> be spaced out with this.
This is part of how Adobe implemented PDF and cannot be change in Perl.

=back

=head2 Known Bugs

=over 4

(none)

=back

=head1 SEE ALSO

=over 4

=item * L<PDF::API2|PDF::API2>

=item * The PDF Reference Manual

Available from Adobe L<http://abode.com/>.

=back

=head1 ORIGINAL AUTHOR

Shawn H. Corey  shawnhcorey@gmail.com

=head2 Contributing Authors

(Insert your name here if you modified this program or its documentation.
 Do not remove this comment.)

=head1 COPYRIGHT & LICENCES

Copyright 2009 by Shawn H. Corey.  All rights reserved.

=head2 Software Licence

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=head2 Document Licence

Permission is granted to copy, distribute and/or modify this document under the
terms of the GNU Free Documentation License, Version 1.2 or any later version
published by the Free Software Foundation; with the Invariant Sections being
ORIGINAL AUTHOR, COPYRIGHT & LICENCES, Software Licence, and Document Licence.

You should have received a copy of the GNU Free Documentation Licence
along with this document; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=head1 ACKNOWLEDGEMENTS

=cut
