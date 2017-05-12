package PostScript::Simple::Table;

use 5.006;
use strict;
use warnings;
use PostScript::Simple;
use PostScript::Metrics;

our $VERSION = '1.02';

sub new
{
  my ($proto) = @_;
  
  my $class = ref($proto) || $proto;
  my $self = {};
  bless ($self, $class);
  return $self;
}

############################################################
#
# text_block - utility method to build multi-paragraph blocks of text
#
# ($width_of_last_line, $ypos_of_last_line, $left_over_text) = text_block(
#   $post_script_handler,
#    $text_to_place,
#    -x        => $left_edge_of_block,
#    -y        => $baseline_of_first_line,
#    -w        => $width_of_block,
#    -h        => $height_of_block,
#   [-lead     => $font_size * 1.2 | $distance_between_lines,]
#   [-parspace => 0 | $extra_distance_between_paragraphs,]
#   [-align    => "left|right|center|justify|fulljustify",]
#   [-hang     => $optional_hanging_indent,]
#);
#
############################################################

sub text_block {
  my $self = shift;
  my $ps = shift;
  my $text = shift;
  my %arg = @_;
  
  my($align,$width,$ypos,$xpos,$line_width,$wordspace, $endw) = (undef,undef,undef,undef,undef,undef,undef,undef);
  my @line = undef;
  my %width = undef;
  # Get the text in paragraphs
  my @paragraphs = split(/\n/, $text);

  $arg{'-lead'} ||= 14;
  
  # calculate width of all words
  my $space_width = $self->getStringWidth("\x20");
  my @words = split(/\s+/, $text);

  foreach (@words) {
    next if exists $width{$_};
    $width{$_} = $self->getStringWidth($_);
  }

  $ypos = $arg{'-y'};
  my @paragraph = split(/ /, shift(@paragraphs));
  my $first_line = 1;
  my $first_paragraph = 1;

  # while we can add another line
  while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {

    unless (@paragraph) {
      last unless scalar @paragraphs;
      @paragraph = split(/ /, shift(@paragraphs));

      $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
      last unless $ypos >= $arg{'-y'} - $arg{'-h'};
      $first_line = 1;
      $first_paragraph = 0;
    }

    $xpos = $arg{'-x'};

    # while there's room on the line, add another word
    @line = ();

    $line_width =0;
    if ($first_line && exists $arg{'-hang'}) {
      my $hang_width = $self->getStringWidth($arg{'-hang'});
      
      $ps->text($xpos, $ypos, $arg{'-hang'});
      
      $xpos         += $hang_width;
      $line_width   += $hang_width;
      $arg{'-indent'} += $hang_width if $first_paragraph;
    } elsif ($first_line && exists $arg{'-flindent'}) {
      $xpos += $arg{'-flindent'};
      $line_width += $arg{'-flindent'};
    } elsif ($first_paragraph && exists $arg{'-fpindent'}) {
      $xpos += $arg{'-fpindent'};
      $line_width += $arg{'-fpindent'};
    } elsif (exists $arg{'-indent'}) {
      $xpos += $arg{'-indent'};
      $line_width += $arg{'-indent'};
    }
    
    while ( @paragraph and $self->getStringWidth(join("\x20", @line)."\x20".$paragraph[0])+$line_width < $arg{'-w'} ) {
      push(@line, shift(@paragraph));
    }
    $line_width += $self->getStringWidth(join('', @line));
    
    # calculate the space width
    if ($arg{'-align'} eq 'fulljustify' or ($arg{'-align'} eq 'justify' and @paragraph)) {
      if (scalar(@line) == 1) {
        @line = split(//,$line[0]);
      }
      $wordspace = ($arg{'-w'} - $line_width) / (scalar(@line) - 1);
      $align='justify';
    } else {
      $align=($arg{'-align'} eq 'justify') ? 'left' : $arg{'-align'};
      $wordspace = $space_width;
    }
    $line_width += $wordspace * (scalar(@line) - 1);

    if ($align eq 'justify') {
      foreach my $word (@line) {
        $ps->text($xpos, $ypos, $word);
        $xpos += ($width{$word} + $wordspace) if (@line);
      }
      $endw = $arg{'-w'};
    } else {
      # calculate the left hand position of the line
      if ($align eq 'right') {
        $xpos += $arg{'-w'} - $line_width;
      } elsif ($align eq 'center') {
        $xpos += ($arg{'-w'}/2) - ($line_width / 2);
      }

      # render the line
      $endw = $ps->text($xpos, $ypos, join("\x20", @line));
    }
    $ypos -= $arg{'-lead'};
    $first_line = 0;
  }
  unshift(@paragraphs, join(' ',@paragraph)) if scalar(@paragraph);
  return ($endw, $ypos, join("\n", @paragraphs))
}


############################################################
#
# table - utility method to build multi-row, multicolumn tables
#
# ($page,$pg_cnt,$cur_y) = table(
#   $pdf_object,
#   $page_object_to_start_on,
#    $table_data, # an arrayref of arrayrefs
#    -x        	=> $left_edge_of_table,
#    -start_y   => $baseline_of_first_line_on_first_page,
#    -next_y   => $baseline_of_first_line_on_succeeding_pages,
#    -start_h   => $baseline_of_first_line_on_first_page,
#    -next_h   => $baseline_of_first_line_on_succeeding_pages,
#   [-w        	=> $table_width,] # technically optional, but almost always a good idea to use
#   [-row_height    	=> $min_row_height,] # minimum height of row
#   [-padding    	=> $cellpadding,] # default 0,
#   [-padding_left    	=> $leftpadding,] # overides -padding 
#   [-padding_right    	=> $rightpadding,] # overides -padding 
#   [-padding_top    	=> $toppadding,] # overides -padding 
#   [-padding_bottom    => $bottompadding,] # overides -padding 
#   [-border     => $border width,] # default 1, use 0 for no border
#   [-border_color     => $border_color,] # default black
#   [-font    => $pdf->corefont,] # default $pdf->corefont('Times',-encode => 'latin1')
#   [-font_size    => $font_sizwe,] # default 12
#   [-font_color    => font_color,] # font color
#   [-font_color_odd    => font_color_odd,] # font color for odd rows
#   [-font_color_even    => font_color_odd,] # font color for odd rows
#   [-background_color	=> 'gray',] # cell background color
#   [-background_color_odd	=> $background_color_odd,] # cell background color for odd rows
#   [-background_color_even	=> $background_color_even,] # cell background color for even rows
# 	[-column_props    => [ 
#		{width => $col_a_width, # width of column 
#		justify => 'left'|'right', # text justify in cell
#		font => $pdf->corefont, # font for this column
#		font_size => $col_a_font_size, # font size for this column
#		font_color => $col_a_font_color, # font color for this column
#		background_color => $col_a_background_color # background color for this column
#		},
#		...
#		]
#	]
#	# column_props is an arrayref of hashrefs, where each hashref sets properties for a column in the table.
#	# -All keys in the hashref are optional, with one caveat in the case of 'width'. See below.
#	# -If used, there should be one hashref for each column, even if it is an empty hashref
#	# -Column_props take precendence over general or odd/even row properties
#	# -If using the 'width' property, it is required for all columns and the total of all column widths should 
#	#  be equal to the -w parameter (overall table width). In other words, if you are going to set individual column widths, 
#	#  set them accurately with respect to overall table width, otherwise behavior will be unpredictable. 
#	#  This is a current limitation, not a feature :-)
#);
#
############################################################	
sub table {
  my $self = shift;
  my $ps = shift;
  my $data = shift;
  my %arg = @_;
  
  # set default properties
  my $fnt_name = $arg{'-font'} || 'Helvetica'; 
  my $fnt_size = $arg{'-font-size'} || 12;
  $ps->setfont($fnt_name,$fnt_size);
  
  my $lead = $arg{'-lead'} || $fnt_size;
  my $pad_left = $arg{'-padding_left'} || $arg{'-padding'} || 0;
  my $pad_right = $arg{'-padding_right'} || $arg{'-padding'} || 0;
  my $pad_top = $arg{'-padding_top'} || $arg{'-padding'} || 0;
  my $pad_bot = $arg{'-padding_bottom'} || $arg{'-padding'} || 0;
  my $pad_w = $pad_left+$pad_right;
  my $pad_h = $pad_top+$pad_bot;
  my $line_w = defined $arg{'-border'}? $arg{'-border'}:1;
  my $min_row_h = defined ($arg{'-row_height'}) && ($arg{'-row_height'} > ($fnt_size + $pad_top + $pad_bot))? $arg{'-row_height'}:$fnt_size + $pad_top + $pad_bot;
  my $row_h = $min_row_h;
  my $pg_cnt = 1;
  my $cur_y = $arg{'-start_y'};

  # Sort out colors
  
  my @border_color = (0,0,0);
  if ($self->getColor($arg{'-border_color'})) {
    @border_color = $self->getColor($arg{'-border_color'});
  }

  my @background_color_even = undef;
  if ($self->getColor($arg{'-background_color_even'})) {
    @background_color_even = $self->getColor($arg{'-background_color_even'});
  } else {
    @background_color_even = $self->getColor($arg{'-background_color'});
  }

  my @background_color_odd = undef;
  if ($self->getColor($arg{'-background_color_odd'})) {
    @background_color_odd = $self->getColor($arg{'-background_color_odd'});
  } else {
    @background_color_odd = $self->getColor($arg{'-background_color'});
  }

  my @font_color_even = (0,0,0);
  if ($self->getColor($arg{'-font_color_even'})) {
    @font_color_even = $self->getColor($arg{'-font_color_even'});
  } else {
    @font_color_even = $self->getColor($arg{'-font_color'});
  }

  my @font_color_odd = (0,0,0);
  if ($self->getColor($arg{'-font_color_odd'})) {
    @font_color_odd = $self->getColor($arg{'-font_color_odd'});
  } else {
    @font_color_odd = $self->getColor($arg{'-font_color'});
  }

  # Build the table
  if(ref $data) {

    # determine column widths based on content
    my $col_props =  $arg{'-column_props'} || []; # a arrayref whose values are a hashref holding the minimum and maximum width of that column
    my $row_props = []; # an array ref of arrayrefs whose values are the actual widths of the column/row intersection
    my ($total_max_w,$total_min_w) = (0,0); # scalars that hold sum of the maximum and minimum widths of all columns
    my ($max_col_w,$min_col_w) = (0,0);
    my $word_w = {};
    my ($row,$col_name,$col_fnt_size,$space_w);
    my $rcnt = 0;
    foreach $row (@$data) {
      my $foo = []; #holds the widths of each column
      for(my $j =0;$j < scalar(@$row);$j++) {

        # look for font information for this column
        $col_fnt_size = $col_props->[$j]->{'font_size'}? $col_props->[$j]->{'font_size'}:$fnt_size;
        if($col_props->[$j]->{'font'}) {
          $ps->setfont($col_props->[$j]->{'font'},$col_fnt_size);
        } else {
          $ps->setfont($fnt_name,$col_fnt_size);
        }
        $space_w = $self->getStringWidth("\x20");
        
        $foo->[$j] = 0;
        $max_col_w = 0;
        $min_col_w = 0;
        my @words = split(/\s+/, $row->[$j]);
        foreach (@words) {
          if(!exists $word_w->{$_}) {
            $word_w->{$_} = $self->getStringWidth($_) + $space_w;
          };
          $foo->[$j] += $word_w->{$_};
          $min_col_w = $word_w->{$_} if $word_w->{$_} > $min_col_w;
          $max_col_w += $word_w->{$_};
        }
        $min_col_w += $pad_w;
        $max_col_w += $pad_w;
        $foo->[$j] += $pad_w;

        # keep a running total of the overall min and max widths
        $col_props->[$j]->{min_w} = $col_props->[$j]->{min_w} || 0;
        $col_props->[$j]->{max_w} = $col_props->[$j]->{max_w} || 0;
        if($min_col_w > $col_props->[$j]->{min_w}) {
          $total_min_w -= $col_props->[$j]->{min_w};
          $total_min_w += $min_col_w;
          $col_props->[$j]->{min_w} = $min_col_w ;
        }
        if($max_col_w > $col_props->[$j]->{max_w}) {
          $total_max_w -= $col_props->[$j]->{max_w};
          $total_max_w += $max_col_w;
          $col_props->[$j]->{max_w} = $max_col_w ;
        }
      }
      $row_props->[$rcnt] = $foo;
      $rcnt++;
		}

    # calc real column widths width
    my ($col_widths,$width) = $self->col_widths($col_props, $total_max_w, $total_min_w, $arg{'-w'});
    $width = $arg{'-w'} if $arg{'-w'};

    my $comp_cnt = 1;
    my (@background_color, @font_color);
    my ($bot_marg, $table_top_y, $text_start, $record, $record_widths);
    $rcnt=0;

    # Each iteration adds a new page as neccessary
    while(scalar(@{$data})) {
      if($pg_cnt == 1){
        $table_top_y = $arg{'-start_y'};
        $bot_marg = $table_top_y - $arg{'-start_h'};
      } else {
        $ps->newpage;
        $table_top_y = $arg{'-next_y'};
        $bot_marg = $table_top_y - $arg{'-next_h'};
      }

      $ps->setfont($fnt_name, $fnt_size);
      $ps->setcolour(@border_color);
      $ps->setlinewidth($line_w);

      #draw the top line
      $cur_y = $table_top_y;
      $ps->line($arg{'-x'}, $cur_y, $arg{'-x'} + $width, $cur_y);
      
      my $safety2 = 20;

      # Each iteration adds a row to the current page until the page is full or there are no more rows to add
      while(scalar(@{$data}) and $cur_y-$row_h > $bot_marg) {
        #remove the next item from $data
        $record = shift @{$data};
        $record_widths = shift @$row_props;
        next unless $record;

        # choose colors for this row
        @background_color = $rcnt%2?@background_color_even:@background_color_odd;
        @font_color = $rcnt%2?@font_color_even:@font_color_odd;

        my $cur_x = $arg{'-x'};

        # draw cell bgcolor
        # this has to be separately from the text loop because we do not know the finel height of the cell until all text has been drawn
        if(@background_color) {
          $cur_x = $arg{'-x'};
          for(my $j =0;$j < scalar(@$record);$j++) {
            if($col_props->[$j]->{'background_color'}) {
              $ps->setcolour($col_props->[$j]->{'background_color'});
            } else {
              $ps->setcolour(@background_color);
            }
            $ps->box({filled => 1}, $cur_x, $cur_y, $cur_x + $col_widths->[$j], $cur_y - $row_h);
            $cur_x += $col_widths->[$j];
          }
        }

        # draw text
        $text_start = $cur_y-$fnt_size-$pad_top;
        $cur_x = $arg{'-x'};
        my $leftovers = undef;
        my $do_leftovers = 0;
        for(my $j =0;$j < scalar(@$record);$j++) {
          next unless $col_props->[$j]->{max_w};
          $leftovers->[$j] = undef;

          # look for column properties that overide row properties
          if($col_props->[$j]->{'font_color'}) {
            $ps->setcolour($col_props->[$j]->{'font_color'});
          } else {
            $ps->setcolour(@font_color);
          }
          $col_fnt_size = $col_props->[$j]->{'font_size'}? $col_props->[$j]->{'font_size'}:$fnt_size;
          if($col_props->[$j]->{'font'}) {
            $ps->setfont($col_props->[$j]->{'font'},$col_fnt_size);
          } else {
            $ps->setfont($fnt_name,$col_fnt_size);
          }
          $col_props->[$j]->{justify} = $col_props->[$j]->{justify} || 'left';
          # if the contents is wider than the specified width, we need to add the text as a text block
          if($record_widths->[$j] and ($record_widths->[$j] > $col_widths->[$j])) {
            my($width_of_last_line, $ypos_of_last_line, $left_over_text) = $self->text_block(
              $ps,
              $record->[$j],
              -x        => $cur_x+$pad_left,
              -y        => $text_start,
              -w        => $col_widths->[$j] - $pad_w,
              -h        => $cur_y - $bot_marg - $pad_top - $pad_bot,
              -align    => $col_props->[$j]->{justify},
              -lead     => $lead
            );
            
            #$lead is added here because $self->text_block returns the incorrect yposition - it is off by $lead
            my $this_row_h = $cur_y - ($ypos_of_last_line +$lead-$pad_bot); 
            $row_h = $this_row_h if $this_row_h > $row_h;
            if($left_over_text) {
              $leftovers->[$j] = $left_over_text;
              $do_leftovers =1;
            }
          } else {
            # Otherwise just use the $ps->text() method
            my $space = $pad_left;
            if($col_props->[$j]->{justify} eq 'right') {
              $space = $col_widths->[$j] - ($self->getStringWidth($record->[$j]) + $pad_right);
            }
            $ps->text($cur_x + $space, $text_start, $record->[$j]);
          }

          $cur_x += $col_widths->[$j];	
        }
        if($do_leftovers) {
          unshift @$data, $leftovers;
          unshift @$row_props, $record_widths;
          $rcnt--;
        }
        
        # draw horizontal lines
        $cur_y -= $row_h;
        $row_h = $min_row_h;
        $ps->setcolour(@border_color);
        $ps->line($arg{'-x'}, $cur_y, $arg{'-x'} + $width, $cur_y);	
        $rcnt++;

      }

      # draw vertical lines
      $ps->setcolour(@border_color);
      $ps->line($arg{'-x'}, $table_top_y, $arg{'-x'}, $cur_y);	
      my $cur_x = $arg{'-x'};
      for(my $j =0;$j < scalar(@$record);$j++){
        $cur_x += $col_widths->[$j];
        $ps->line($cur_x, $table_top_y, $cur_x, $cur_y);	
      }
      $pg_cnt++;
    }
	}

	#return ($page,--$pg_cnt,$cur_y);
  return $cur_y;
}

	
# calculate the column widths	
sub col_widths {
  my $self = shift;
  my $col_props = shift;
  my $max_width = shift;
  my $min_width = shift;
  my $avail_width = shift;	
  
  my$calc_widths;
  my $colname;
  my $total = 0;
  for(my $j =0;$j < scalar(@$col_props);$j++) {
  #foreach $colname (keys %$col_props){
    
    if( $col_props->[$j]->{width}) {
      # if the width is specified, use that
      $calc_widths->[$j] = $col_props->[$j]->{width};
    } elsif( !$avail_width || !$col_props->[$j]->{max_w}) {
      # if no avail_width is specified
      # or there is no max_w for the column specified, use the max width
      $calc_widths->[$j] = 	$col_props->[$j]->{max_w};
    } elsif($avail_width > $max_width and $max_width > 0) {
      # if the available space is more than the max, grow each column proportionally 
      $calc_widths->[$j] = 	$col_props->[$j]->{max_w} * ($avail_width/$max_width);
    } elsif($min_width > $avail_width) {
      # if the min width is greater than the available width, return the min width
      $calc_widths->[$j] = 	$col_props->[$j]->{min_w};
    } else {
      # else use the autolayout algorithm from RFC 1942
      $calc_widths->[$j] = $col_props->[$j]->{min_w}+(($col_props->[$j]->{max_w} - $col_props->[$j]->{min_w}) * ($avail_width -$min_width))/ ($max_width -$min_width);
    }
    $total += $calc_widths->[$j];
  }
  return ($calc_widths,$total);
}


sub getStringWidth {
  my $self = shift;
  my $text = shift;

  my $font = $self->{current_font} || 'Helvetica';
  my $font_size = $self->{current_font_size} || 12;

  # check to make sure that this font is supported by Metrics.pm !
  # Helvetica-Italic is not supported by PostScript::Metrics, therefore 
  # we cannot underline this font
  return PostScript::Metrics::stringwidth($text,$font,$font_size); 
}


sub getColor {
  my $self = shift;
  my $color_string = shift;
  
  my @color = ();
  
  if (!defined($color_string)) {
    # return undef if not defined so a default can be used
    return undef;
  } 
   
  if ($color_string =~ /^\#[0-9a-fA-F]{6}/) {
    # Given hex string, convert to base 10 array
    $color_string =~ /^\#(..)(..)(..)/;
    $color[0] = eval "0x$1";
    $color[1] = eval "0x$2";
    $color[2] = eval "0x$3";
    
  } else {
    warn "found color code";
    # Given color code, store in array[0]
    @color = ($color_string);
    
  }
  
  return @color;
}


1;
__END__


=head1 NAME

PostScript::Simple::Table - Adds easy table creation to PostScript::Simple

=head1 SYNOPSIS

  use PostScript::Simple;
  use PostScript::Simple::Table;

  $ps = new PostScript::Simple(
    papersize => "letter",
    colour => 1,
    eps => 0,
  );
  
  $ps->newpage;

  # some data to layout
  my $some_data =[
    ["1 Lorem ipsum dolor",
    "Donec odio neque, faucibus vel",
    "consequat quis, tincidunt vel, felis."],
    ["Nulla euismod sem eget neque.",
    "Donec odio neque",
    "Sed eu velit."],
    ... and so on
  ];
  
  my $pstable = new PostScript::Simple::Table;
  
  # build the table layout
  $pstable->table(
    # required params
    $ps,
    $some_data,
    -x  => $left_edge_of_table,
    -start_y => 500,
    -next_y => 700,
    -start_h => 300,
    -next_h => 500,
    # some optional params
    -w => 570, 
    -padding => 5,
    -padding_right => 10, 
    -background_color_odd => "gray", 
    -background_color_even => "#FFFFCC", #cell background color for even rows
  );

=head1 DESCRIPTION

This class is a utility for use with the PostScript::Simple module from CPAN. 
It can be used to display text data in a table layout within a PostScript 
document. The text data must be in a 2d array (such as returned by a DBI 
statement handle fetchall_arrayref() call). The PDF::Table will automatically 
add as many new pages as necessary to display all of the data. Various layout 
properties, such as font, font size, and cell padding and background color can 
be specified for each column and/or for even/odd rows. See the METHODS section.


=head1  METHODS

=head2 new

=over

Returns an instance of the class. There are no parameters.

=back

=head2 table($pdf, $page_obj, $data, %opts) 

=over

 The main method of this class. Takes a PDF::API2 instance, a page instance, 
 some data to build the table and formatting options. The formatting options 
 should be passed as named parameters. This method will add more pages to the 
 pdf instance as required based on the formatting options and the amount of 
 data.

=back

=over

 The return value is the y position of the table bottom.

=back

=over

=item Example:

 ($table_bot_y) = $pdftable->table(
	 $ps, # A PostScript::Simple instance
	 $data, # 2D arrayref of text strings
	 -x  => $left_edge_of_table,
	 -start_y   => $baseline_of_first_line_on_first_page,
	 -next_y   => $baseline_of_first_line_on_succeeding_pages,
	 -start_h   => $height_on_first_page,
	 -next_h => $height_on_succeeding_pages,
	 [-w  => 570,] # width of table. technically optional, but almost always a good idea to use
	 [-padding => "5",] # cell padding
	 [-padding_top => "10",] #top cell padding, overides -pad 
	 [-padding_right  => "10",] #right cell padding, overides -pad 
	 [-padding_left  => "10",] #left padding padding, overides -pad 
	 [-padding_bottom  => "10",] #bottom padding, overides -pad
	 [-border  => 1,] # border width, default 1, use 0 for no border
	 [-border_color => "red",] # default black
	 [-font  => "Helvetica",] # default font
	 [-font_size => 12,]
	 [-font_color_odd => "purple",]
	 [-font_color_even => "black",]
	 [-background_color_odd	=> "gray",] #cell background color for odd rows
	 [-background_color_even => "#FFFFCC",] #cell background color for even rows
	 [-column_props => $col_props] # see below
 )

=back

=over

If the -column_props parameter is used, it should be an arrayref of hashrefs, 
with one hashref for each column of the table. Each hashref can contain any 
of keys shown here:

=back

=over

  $col_props = [
	{
		width => 100,  
		justify => "[left|right|center]",
		font => $pdf->corefont("Times", -encoding => "latin1"),
		font_size => 10
		font_color=> "red"
		background_color => "yellow", 
	},
	# etc.
  ];

=back

=over
	
If the "width" parameter is used for -col_props, it should be specified for 
every column and the sum of these should be exacty equal to the -w parameter, 
otherwise Bad Things may happen. In cases of a conflict between column 
formatting and odd/even row formatting, the former will oeverride the latter.

=back


=head2 text_block($txtobj,$string,-x => $x, -y => $y, -w => $width, -h => $height)

=over

Utility method to create a block of text. The block may contain multiple paragraphs.

=back

=over

=item Example:

=back

=over

 $left_over_text = $pdftable->text_block(
    $ps,
    $text_to_place,
    -x        => $left_edge_of_block,
    -y        => $baseline_of_first_line,
    -w        => $width_of_block,
    -h        => $height_of_block,
   [-lead     => $font_size * 1.2 | $distance_between_lines,]
   [-parspace => 0 | $extra_distance_between_paragraphs,]
   [-align    => "left|right|center|justify|fulljustify",]
   [-hang     => $optional_hanging_indent,]
 );


=back

=head1 SEE ALSO

This is a port from Daemmon Hughes's PDF::Table to PostScript::Simple.

=head1 AUTHOR

Aaron Mitti, E<lt>mitti@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

=item Copyright (C) 2005 by Aaron Mitti
=item Copyright (C) 2005 by Daemmon Hughes
=item Copyright (C) 2005 by Rick Measham
=item Copyright (C) 2004 by Stone Environmental Inc.
=item All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
