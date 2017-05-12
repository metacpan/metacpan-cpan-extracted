package PDF::API2::Ladder;

use strict;
use 5.008_005;
our $VERSION = '0.03';

BEGIN {
    use PDF::API2;
    use constant mm => 25.4 / 72;
    use constant in => 1 / 72;
    use constant pt => 1;

    use utf8;
}

=encoding utf-8

=head1 NAME

PDF::API2::Ladder - Creates PDFs a line at a time, much like the rungs on a ladder.

=head1 SYNOPSIS

  use PDF::API2::Ladder;

  # Create a new PDF::Ladder Object
  $pdf = PDF::Ladder->new(   font_size       => $font_size,
                             lead            => $lead,
                             font            => 'Georgia',
                             show_margins    => $show_margins,
                             margin_top      => .5/in,
                             margin_bottom   => .5/in,
                             line_height     => $line_height);

  # Create a Rung at the top of the page (since its the first) that is center.
  $pdf->add_rung("An Amazing Play", align  => 'center');
  # Create a Rung underneath that, which is not centered
  $pdf->add_rung("Actor1: 'To be or not 2 B. That is the answer!');

=head1 DESCRIPTION

PDF::API2::Ladder is a simplified way of creating PDFs using the awesome module PDF::API2. PDF::API2::Ladder builds PDFs in a top down fashion much like rungs on a ladder. The exception to the rung style is what is called a Blob. Blobs do not have a set height and adapt to their contents height instead. New pages are created automatically when a rung or blob goes off the end of the page.

=head1 METHODS

   TODO

=over

=cut

sub new {
   my $class=shift(@_);
   my %opt=@_;
   my $self={};
   bless($self, $class);

   # File Preferences
   $self->{path} = ($opt{'path'}) ? $opt{'path'} : './';
   $self->{file_name} = $opt{'filename'};

   # ----- General Format -----
   $self->{media_width} = ($opt{'media_width'}) ? $opt{'media_width'} : 8.5/in;
   $self->{media_height} = ($opt{'media_height'}) ? $opt{'media_height'} : 11/in;

   $self->{show_margins} = $opt{'show_margins'};

   # Margins
   $self->{margin_top} = ($opt{'margin_top'}) ? $opt{'margin_top'} : 1/in;
   $self->{margin_right} = ($opt{'margin_right'}) ? $opt{'margin_right'} : 1/in;
   $self->{margin_bottom} = ($opt{'margin_bottom'}) ? $opt{'margin_bottom'} : 1/in;
   $self->{margin_left} = ($opt{'margin_left'}) ? $opt{'margin_left'} : 1/in;
   if ($opt{'margin'}) {
      $self->{margin_top} = $self->{margin_right} = $self->{margin_bottom} = $self->{margin_left} = $opt{'margin'};
   }

   # Line Format
   $self->{line_height} = ($opt{'line_height'}) ? $opt{'line_height'} : 1/in;
   $self->{current_line_offset} = 0; # Lines are indexed starting at 1

   # Fonts
   $self->{font} = ($opt{'font'}) ? $opt{'font'} : 'Helvetica';
   $self->{font_size} = ($opt{'font_size'}) ? $opt{'font_size'} : 12/pt;
   $self->{lead} = ($opt{'lead'}) ? $opt{'lead'} : 7/pt;
   $self->{font_color} = ($opt{'font_color'}) ? $opt{'font_color'} : 'black';
   $self->{charspace} = (defined $opt{'charspace'}) ? $opt{'charspace'} : 0;

   # Setup
   if ($self->{file_name}) {
      $self->{pdf} = PDF::API2->new( -file => $self->{path}.$self->{file_name} );
   } else {
      $self->{pdf} = PDF::API2->new();
   }

   # Declar the included fonts
   $self->{fonts} = {
       Helvetica => {
           Bold         => $self->{pdf}->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
           Roman        => $self->{pdf}->corefont( 'Helvetica',         -encoding => 'latin1' ),
           Italic       => $self->{pdf}->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
           BoldItalic   => $self->{pdf}->corefont( 'Helvetica-BoldOblique',    -encoding => 'latin1' ),
           Italic => $self->{pdf}->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
       },
       Times => {
           Bold         => $self->{pdf}->corefont( 'Times-Bold',   -encoding => 'latin1' ),
           Roman        => $self->{pdf}->corefont( 'Times',        -encoding => 'latin1' ),
           Italic       => $self->{pdf}->corefont( 'Times-Italic', -encoding => 'latin1' ),
           BoldItalic   => $self->{pdf}->corefont( 'Times-BoldItalic', -encoding => 'latin1' ),
       },
       Georgia => {
           Bold         => $self->{pdf}->corefont( 'Georgia,Bold',   -encoding => 'latin1' ),
           Roman        => $self->{pdf}->corefont( 'Georgia',        -encoding => 'latin1' ),
           Italic       => $self->{pdf}->corefont( 'Georgia,Italic', -encoding => 'latin1' ),
           BoldItalic   => $self->{pdf}->corefont( 'Georgia,BoldItalic', -encoding => 'latin1' ),
       },
   };
   if ($opt{'fonts'}) {
      $self->{fonts} = $opt{'fonts'};
   }

   $self->start_new_page();

   return $self;
}

#=item $pdf->add_rung %opts
#
#Creates a new "rung" or line in the PDF. When provided with specific parameters, the text is changed accordingly.
#
#B<Example:>
#
#    $pdf = PDF::API2->new();
#    ...
#    print $pdf->stringify;
#
#    $pdf = PDF::API2->new();
#    ...
#    $pdf->saveas("our/new.pdf");
#
#    $pdf = PDF::API2->new(-file => 'our/new.pdf');
#    ...
#    $pdf->save;
#
#=cut
sub add_rung {
   my $self=shift;
   my $text = shift;
   my %options = @_;

   my $bold = ($options{'bold'}) ? 1 : 0;
   my $oblique = ($options{'oblique'}) ? 1 : 0;
   my $indent = ($options{'indent'}) ? $options{'indent'} : 0;
   my $align = ($options{'align'}) ? $options{'align'} : 'left';
   # Font parameters
   my $font_size = ($options{'font_size'}) ? $options{'font_size'} : $self->{font_size};
   my $fonts = ($options{'fonts'}) ? $options{'fonts'} : $self->{fonts};
   my $font = ($options{'font'}) ? $options{'font'} : $self->{font};
   my $font_color = ($options{'font_color'}) ? $options{'font_color'} : $self->{font_color};
   my $charspace = (defined $options{'charspace'}) ? $options{'charspace'} : $self->{charspace};

   my $line_height = ($options{'line_height'}) ? $options{'line_height'} : $self->{line_height};
   my $lead = ($options{'lead'}) ? $options{'lead'} : $self->{lead};

   # Check to see if the next rung will fit 
   if ( $self->{media_height} - ($self->{margin_top} + $self->{margin_bottom} + $self->{current_line_offset} ) < $line_height ) {
      $self->start_new_page();
   }

   my $text_element = $self->{current_page}->text;

   # Font
   my $font_key = '';
   if ($bold) {   $font_key .= "Bold"; }
   if ($oblique) {   $font_key .= "Italic"; }
   if ($font_key eq '') { $font_key = 'Roman'; }

   $text_element->font( $fonts->{$font}{$font_key}, $font_size );
   $text_element->fillcolor($font_color);
   $text_element->charspace($charspace);

   my ( $endw, $ypos, $paragraph ) = text_block(
      $text_element,
      $text,
      -x        => $self->{margin_left},
      -y        => $self->{'media_height'} - ( $self->{margin_top} + $self->{current_line_offset} + $lead ),
      -w        => $self->{media_width} - $self->{margin_left} - $self->{margin_right},
      -h        => $line_height,
      -lead     => $lead,
      -indent   => $indent,
      -parspace => 6/pt,
      -align    => $align,
   );

   $self->{current_line_offset} += $line_height;
   
   return 1;
}

#=item $pdf->add_blob %opts
#
#Creates a new set of lines with undetermined height in the PDF.
#
#B<Example:>
#
#    $pdf = PDF::API2->new();
#    ...
#    print $pdf->stringify;
#
#    $pdf = PDF::API2->new();
#    ...
#    $pdf->saveas("our/new.pdf");
#
#    $pdf = PDF::API2->new(-file => 'our/new.pdf');
#    ...
#    $pdf->save;
#
#=cut
sub add_blob {
   my $self=shift;
   my $text = shift;
   my %options = @_;

   my $fonts = ($options{'fonts'}) ? $options{'fonts'} : $self->{fonts};
   my $font = ($options{'font'}) ? $options{'font'} : $self->{font};
   my $bold = ($options{'bold'}) ? 1 : 0;
   my $oblique = ($options{'oblique'}) ? 1 : 0;
   my $font_color = ($options{'font_color'}) ? $options{'font_color'} : $self->{font_color};
   my $charspace = (defined $options{'charspace'}) ? $options{'charspace'} : $self->{charspace};

   my $line_height = ($options{'line_height'}) ? $options{'line_height'} : $self->{line_height};
   my $lead = ($options{'lead'}) ? $options{'lead'} : $self->{lead};

   # Check to see if the next rung will fit 
   if ( $self->{media_height} - ($self->{margin_top} + $self->{margin_bottom} + $self->{current_line_offset} ) < $line_height ) {
      $self->start_new_page();
   }

   my $text_element = $self->{current_page}->text;
   # Font
   my $font_key = '';
   if ($bold) {   $font_key .= "Bold"; }
   if ($oblique) {   $font_key .= "Italic"; }
   if ($font_key eq '') { $font_key = 'Roman'; }

   $text_element->font( $fonts->{$font}{$font_key}, $self->{font_size} );
   $text_element->fillcolor($font_color);
   $text_element->charspace($charspace);

   # Check to see if the next rung will fit 
   my ( $endw, $ypos, $paragraph ) = text_block(
      $text_element,
      $text,
      -x          => $self->{margin_left},
      -y          => $self->{'media_height'} - ( $self->{margin_top} + $self->{current_line_offset} + $lead ),
      -w          => $self->{media_width} - $self->{margin_left} - $self->{margin_right},
      -lead       => $lead,
      -heightless => 1,
      -measure    => 1,
      -parspace   => 6/pt,
      -align      => 'left',
   );
   if ( $ypos < $self->{margin_top} ) {
      $self->start_new_page();
      $text_element = $self->{current_page}->text;
      # Font
      my $font_key = '';
      if ($bold) {   $font_key .= "Bold"; }
      if ($oblique) {   $font_key .= "Italic"; }
      if ($font_key eq '') { $font_key = 'Roman'; }

      $text_element->font( $fonts->{$font}{$font_key}, $self->{font_size} );
      $text_element->fillcolor($font_color);
   }

   my ( $endw, $ypos, $paragraph ) = text_block(
      $text_element,
      $text,
      -x          => $self->{margin_left},
      -y          => $self->{'media_height'} - ( $self->{margin_top} + $self->{current_line_offset} + $lead ),
      -w          => $self->{media_width} - $self->{margin_left} - $self->{margin_right},
      -heightless => 1,
      -lead       => $lead,
      -parspace   => 6/pt,
      -align      => 'left',
   );

   $self->{current_line_offset} += $self->{'media_height'} - ( $self->{margin_top} + $self->{current_line_offset} + $lead ) - $ypos;
   
   return 1;
}

#=item $pdf->start_new_page %opts
#
#Ends current page PDF.
#
#B<Example:>
#
#    $pdf = PDF::API2->new();
#    ...
#    print $pdf->stringify;
#
#    $pdf = PDF::API2->new();
#    ...
#    $pdf->saveas("our/new.pdf");
#
#    $pdf = PDF::API2->new(-file => 'our/new.pdf');
#    ...
#    $pdf->save;
#
#=cut
sub start_new_page {
   my $self=shift;
   my %options = @_;

   $self->{current_page} = $self->{pdf}->page;
   
   # Set pdf sizes
   $self->{current_page}->mediabox($self->{media_width},$self->{media_height});

   $self->{current_line_offset} = 0;

   # Margin debuggin
   if ($self->{show_margins}) {
      my $margins = $self->{'current_page'}->gfx();
      $margins->strokecolor('red');

      # top margin
      $margins->move($self->{margin_left}, $self->{media_height} - $self->{margin_top});
      $margins->line($self->{media_width} - $self->{margin_right}, $self->{media_height} - $self->{margin_top});

      # right margin
      $margins->move($self->{media_width} - $self->{margin_right}, $self->{media_height} - $self->{margin_top});
      $margins->line($self->{media_width} - $self->{margin_right}, $self->{margin_bottom});

      # bottom margin
      $margins->move($self->{media_width} - $self->{margin_right}, $self->{margin_bottom});
      $margins->line($self->{margin_left}, $self->{margin_bottom});

      # left margin
      $margins->move($self->{margin_left}, $self->{margin_bottom});
      $margins->line($self->{margin_left}, $self->{media_height} - $self->{margin_top});
   
      # Stroke lines
      $margins->stroke;
   }

   return 1;
}

#=item $pdf->save %opts
#
#Saves out the PDF.
#
#B<Example:>
#
#    $pdf = PDF::API2->new();
#    ...
#    print $pdf->stringify;
#
#    $pdf = PDF::API2->new();
#    ...
#    $pdf->saveas("our/new.pdf");
#
#    $pdf = PDF::API2->new(-file => 'our/new.pdf');
#    ...
#    $pdf->save;
#
#=cut
sub save {
   my $self=shift;
   my %options = @_;

   $self->{pdf}->save;
   $self->{pdf}->end();
   
   return 1;
}

#=item $pdf->stringify %opts
#
#Saves out the PDF as string.
#
#B<Example:>
#
#    $pdf = PDF::API2->new();
#    ...
#    print $pdf->stringify;
#
#    $pdf = PDF::API2->new();
#    ...
#    $pdf->saveas("our/new.pdf");
#
#    $pdf = PDF::API2->new(-file => 'our/new.pdf');
#    ...
#    $pdf->save;
#
#=cut
sub stringify {
   my $self=shift;
   my %options = @_;

   return $self->{pdf}->stringify();
}

#--- Text block -------------------------------------------------------------
#  This code was borrowed from a tutorial. It is an easy way to create paragraphs in PDFs.
sub text_block {
   my $text_object = shift;
   my $text        = shift;
   
   my $endw;
 
   my %arg = @_;
 
   # Get the text in paragraphs
   my @paragraphs = split( /\n/, $text );
 
   # calculate width of all words
   my $space_width = $text_object->advancewidth(' ');
 
   my @words = split( /\s+/, $text );
   my %width = ();
   foreach (@words) {
       next if exists $width{$_};
       $width{$_} = $text_object->advancewidth($_);
   }
 
   my $ypos = $arg{'-y'};
   my @paragraph = split( / /, shift(@paragraphs) );
 
   my $first_line      = 1;
   my $first_paragraph = 1;

   if (not exists $arg{'-h'}) { $arg{'-heightless'} = 1; }
 
   # while we can add another line

   while ( ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) or $arg{'-heightless'} ) {
       unless (@paragraph) {
           last unless scalar @paragraphs;
 
           @paragraph = split( / /, shift(@paragraphs) );
 
           $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            if (not $arg{'-heightless'}) {
              last unless $ypos >= $arg{'-y'} - $arg{'-h'};
            }
 
           $first_line      = 1;
           $first_paragraph = 0;
       }
 
       my $xpos = $arg{'-x'};
 
       # while there's room on the line, add another word
       my @line = ();
 
       my $line_width = 0;
       if ( $first_line && exists $arg{'-hang'} ) {
 
           my $hang_width = $text_object->advancewidth( $arg{'-hang'} );
 
            if (not ($arg{'-heightless'} and $arg{'-measure'}) ) {   # skip adding text if just measuring
              $text_object->translate( $xpos, $ypos );
              $text_object->text( $arg{'-hang'} );
            }
 
           $xpos       += $hang_width;
           $line_width += $hang_width;
           $arg{'-indent'} += $hang_width if $first_paragraph;
 
       }
       elsif ( $first_line && exists $arg{'-flindent'} ) {
 
           $xpos       += $arg{'-flindent'};
           $line_width += $arg{'-flindent'};
 
       }
       elsif ( $first_paragraph && exists $arg{'-fpindent'} ) {
 
           $xpos       += $arg{'-fpindent'};
           $line_width += $arg{'-fpindent'};
 
       }
       elsif ( exists $arg{'-indent'} ) {
 
           $xpos       += $arg{'-indent'};
           $line_width += $arg{'-indent'};
 
       }
 
       while ( @paragraph
           and $line_width + ( scalar(@line) * $space_width ) +
           $width{ $paragraph[0] } < $arg{'-w'} )
       {
 
           $line_width += $width{ $paragraph[0] };
           push( @line, shift(@paragraph) );
 
       }
 
       # calculate the space width
       my ( $wordspace, $align );
       if ( $arg{'-align'} eq 'fulljustify'
           or ( $arg{'-align'} eq 'justify' and @paragraph ) )
       {
 
           if ( scalar(@line) == 1 ) {
               @line = split( //, $line[0] );
 
           }
           $wordspace = ( $arg{'-w'} - $line_width ) / ( scalar(@line) - 1 );
 
           $align = 'justify';
       }
       else {
           $align = ( $arg{'-align'} eq 'justify' ) ? 'left' : $arg{'-align'};
 
           $wordspace = $space_width;
       }
       $line_width += $wordspace * ( scalar(@line) - 1 );
 
       if ( $align eq 'justify' ) {
           foreach my $word (@line) {
 
            if (not ($arg{'-heightless'} and $arg{'-measure'}) ) {   # skip adding text if just measuring
               $text_object->translate( $xpos, $ypos );
               $text_object->text($word, -indent   => $arg{'-indent'});
            }
 
               $xpos += ( $width{$word} + $wordspace ) if (@line);
 
           }
           $endw = $arg{'-w'};
       }
       else {
 
           # calculate the left hand position of the line
           if ( $align eq 'right' ) {
               $xpos += $arg{'-w'} - $line_width;
 
           }
           elsif ( $align eq 'center' ) {
               $xpos += ( $arg{'-w'} / 2 ) - ( $line_width / 2 );
 
           }
 
           # render the line
            if (not ($arg{'-heightless'} and $arg{'-measure'}) ) {   # skip adding text if just measuring
              $text_object->translate( $xpos, $ypos );
    
              $endw = $text_object->text( join( ' ', @line ), -indent   => $arg{'-indent'} );
            }
 
       }
       $ypos -= $arg{'-lead'};
       $first_line = 0;
 
   }

   unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
 
   return ( $endw, $ypos, join( "\n", @paragraphs ) )
 
 }

1;
__END__

=back

=head1 AUTHOR

Sean Zellmer E<lt>sean@lejeunerenard.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Sean Zellmer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 8

=item L<PDF::API2>

=item L<PDF::API2::Simple>

=back

=cut
