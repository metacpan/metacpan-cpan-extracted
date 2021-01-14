package PDF::TextBlock;

use strict;
use warnings;
use Carp qw( croak );
use File::Temp qw(mktemp);
use Class::Accessor::Fast;
use PDF::TextBlock::Font;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( pdf page text fonts x y w h lead parspace align hang flindent fpindent indent ));

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my $debug = 0;

=head1 NAME

PDF::TextBlock - Easier creation of text blocks when using PDF::API2
or PDF::Builder

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

  use PDF::API2;   # PDF::Builder also works
  use PDF::TextBlock;

  my $pdf = PDF::API2->new( -file => "40-demo.pdf" );
  my $tb  = PDF::TextBlock->new({
     pdf       => $pdf,
     fonts     => {
        b => PDF::TextBlock::Font->new({
           pdf  => $pdf,
           font => $pdf->corefont( 'Helvetica-Bold', -encoding => 'latin1' ),
        }),
     },
  });
  $tb->text(
     $tb->garbledy_gook .
     ' <b>This fairly lengthy</b>, rather verbose sentence <b>is tagged</b> to appear ' .
     'in a <b>different font, specifically the one we tagged b for "bold".</b> ' .
     $tb->garbledy_gook .
     ' <href="http://www.omnihotels.com">Click here to visit Omni Hotels.</href> ' .
     $tb->garbledy_gook . "\n\n" .
     "New paragraph.\n\n" .
     "Another paragraph."
  );
  $tb->apply;
  $pdf->save;
  $pdf->end;

=head1 DESCRIPTION

Neither Rick Measham's excellent L<PDF::API2> tutorial nor L<PDF::FromHTML> are able to cope with
wanting some words inside a text block to be bold. This module makes that task trivial.

Simply define whatever tags you want PDF::TextBlock to honor inside the fonts hashref, and
then you are free to use HTML-like markup in the text attribute and we'll render those fonts
for you. 

We also honor the HTML-like tag <href>. This means that we add annotation to the PDF for you
which makes the word(s) you wrap in <href> clickable, and we underline those words.

Note this markup syntax is very rudimentary. We do not support HTML.
Tags cannot overlap each other. There is no way to escape tags inside text().

The tests in t/ generate .pdf files. You might find those examples helpful.
Watch out for 20-demo.pdf. It spits.  :)

=head1 METHODS

=head2 new

Our attributes are listed below. They can be set when you call new(), 
and/or added/changed individually at any time before you call apply(). 

=over

=item pdf

A L<PDF::API2> or L<PDF::Builder> object. You must provide this. 

=item text

The text of your TextBlock. Defaults to garbledy_gook().

=item x

X position from the left of the document. Default is 20/mm.

=item y

Y position from the bottom of the document. Default is 238/mm.

=item w

Width of this text block. Default is 175/mm.

=item h

Height of this text block. Default is 220/mm.

=item align

Alignment of words in the text block. Default is 'justify'. Legal values:

=over

=item justify

Spreads words out evenly in the text block so that each line ends in the same spot
on the right side of the text block. The last line in a paragraph (too short to fill
the entire line) will be set to 'left'.

=item fulljustify

Like justify, except that the last line is also spread across the page. The last
line can look very odd with very large gaps.

=item left

Aligns each line to the left.

=item right

Aligns each line to the right.

=back

=item page

A L<PDF::API2::Page> or L<PDF::Builder::Page> object. If you don't set this 
manually then we create a new page for you when you call apply(). 

If you want multiple PDF::TextBlock objects to all render onto the same 
page, you could create a PDF::API2 or PDF::Builder page yourself, and pass 
it in to each PDF::TextBlock object:

  my $pdf = PDF::API2->new( -file => "mytest.pdf" );
  my $page = $pdf->page();

  my $tb  = PDF::TextBlock->new({
     pdf  => $pdf,
     page => $page,     # <---
     ...

Or after your first apply() you could grab $page off of $tb.

  my $pdf = PDF::API2->new( -file => "mytest.pdf" );
  my $tb  = PDF::TextBlock->new({
     pdf  => $pdf,
     ...
  });
  $tb->apply;
  my $page = $tb->page;   # Use the same page

  my $tb2 = PDF::TextBlock->new({
     pdf  => $pdf,
     page => $page,     # <---
     ...

=item fonts

A hashref of HTML-like markup tags and what font objects you want us to use 
when we see that tag in text(). 

  my $tb  = PDF::TextBlock->new({
     pdf       => $pdf,
     fonts     => {
        # font is a PDF::API2::Resource::Font::CoreFont
        b => PDF::TextBlock::Font->new({
           pdf  => $pdf,
           font => $pdf->corefont( 'Helvetica-Bold', -encoding => 'latin1' ),
           fillcolor => '#ff0000',  # red
        }),
     },
  });

=back

The attributes below came from Rick's text_block(). They do things, 
but I don't really understand them. POD patches welcome.  :) 

L<http://rick.measham.id.au/pdf-api2/>

=over

=item lead

Leading distance (baseline to baseline spacing). Default is 15/pt.

=item parspace

Extra gap between paragraphs. Default is 0/pt.

=item hang

=item flindent

=item fpindent

=item indent

=back

=head2 apply

This is where we do all the L<PDF::API2> or L<PDF::Builder> heavy lifting 
for you.

Returns $endw, $ypos, $overflow. 

I'm not sure what $endw is good for, it's straight from Ricks' code.  :)

$ypos is useful when you have multiple TextBlock objects and you want to start
the next one wherever the previous one left off.

  my ($endw, $ypos) = $tb->apply();
  $tb->y($ypos);
  $tb->text("a bunch more text");
  $tb->apply();

$overflow is whatever text() didn't fit inside your TextBlock. 
(Too much text? Your font was too big? You set w and h too small?)

The original version of this method was text_block(), which is (c) Rick Measham, 2004-2007. 
The latest version of text_block() can be found in the tutorial located at L<http://rick.measham.id.au/pdf-api2/>.
text_block() is released under the LGPL v2.1.

=cut

sub apply {
   my ($self, %args) = @_;

   my $pdf  = $self->pdf;
   unless (ref $pdf eq "PDF::API2" ||
           ref $pdf eq "PDF::Builder") {
      croak "pdf attribute (a PDF::API2 or PDF::Builder object) required";
   }

   $self->_apply_defaults();

   my $text = $self->text;
   my $page = $self->page;

   # Build %content_texts. A hash of all PDF::API2::Content::Text objects
   # (or PDF::Builder), one for each tag (<b> or <i> or whatever) in $text.
   my %content_texts;
   foreach my $tag (($text =~ /<(\w*)[^\/].*?>/g), "default") {       
      next if ($content_texts{$tag});
      my $content_text = $page->text;      # PDF::API2::Content::Text obj
      my $font;
      if ($self->fonts && $self->fonts->{$tag}) {
         $debug && warn "using the specific font you set for <$tag>";
         $font = $self->fonts->{$tag};
      } elsif ($self->fonts && $self->fonts->{default}) {
         $debug && warn "using the default font you set for <$tag>";
         $font = $self->fonts->{default};
      } else {
         $debug && warn "using PDF::TextBlock::Font default font for <$tag> since you specified neither <$tag> nor a 'default'";
         $font = PDF::TextBlock::Font->new({ pdf => $pdf });
         $self->fonts->{$tag} = $font;
      }
      $font->apply_defaults;
      $content_text->font($font->font, $font->size);
      $content_text->fillcolor($font->fillcolor);
      $content_text->translate($self->x, $self->y);
      $content_texts{$tag} = $content_text;
   }

   my $content_text = $content_texts{default};

   if ($self->align eq "text_right") {
      # Special case... Single line of text that we don't paragraph out...
      #    ... why does this exist? TODO: why can't align 'right' do this? 
      #    t/20-demo.t doesn't work align 'right', but I don't know why.
      $content_text->text_right($text);
      return 1;
   }

   my ($endw, $ypos);

   # Get the text in paragraphs
   my @paragraphs = split( /\n/, $text );

   # calculate width of all words
   my $space_width = $content_text->advancewidth(' ');

   my @words = split( /\s+/, $text );

   # Build a hash of widths we refer back to later.
   my $current_content_text = $content_texts{default};
   my $tag;
   my %width = ();
   foreach my $word (@words) {
      next if exists $width{$word};
      if (($tag) = ($word =~ /<(.*?)>/)) {
         if ($tag !~ /\//) {
            unless ($content_texts{$tag}) {
               # Huh. They didn't declare this one, so we'll put default in here for them.
               $content_texts{$tag} = $content_texts{default};
            }
            $current_content_text = $content_texts{$tag};
         }
      }
           
      my $stripped = $word;
      $stripped =~ s/<.*?>//g;
      $width{$word} = $current_content_text->advancewidth($stripped);

      if ($tag && $tag =~ /^\//) {
         $current_content_text = $content_texts{default};
      }
   }

   $ypos = $self->y;
   my @paragraph = split( / /, shift(@paragraphs) );

   my $first_line      = 1;
   my $first_paragraph = 1;

   my ($href);
   $current_content_text = $content_texts{default};

   # while we can add another line
   while ( $ypos >= $self->y - $self->h + $self->lead ) {

      unless (@paragraph) {
         last unless scalar @paragraphs;

         @paragraph = split( / /, shift(@paragraphs) );

         $ypos -= $self->parspace if $self->parspace;
         last unless $ypos >= $self->y - $self->h;

         $first_line      = 1;
         $first_paragraph = 0;
      }

      my $xpos = $self->x;

      # while there's room on the line, add another word
      my @line = ();

      my $line_width = 0;
      if ( $first_line && defined $self->hang ) {
         my $hang_width = $content_text->advancewidth( $self->hang );

         $content_text->translate( $xpos, $ypos );
         $content_text->text( $self->hang );

         $xpos       += $hang_width;
         $line_width += $hang_width;
         $self->indent($self->indent + $hang_width) if $first_paragraph;
      } elsif ( $first_line && defined $self->flindent ) {
         $xpos       += $self->flindent;
         $line_width += $self->flindent;
      } elsif ( $first_paragraph && defined $self->fpindent ) {
         $xpos       += $self->fpindent;
         $line_width += $self->fpindent;
      } elsif ( defined $self->indent ) {
         $xpos       += $self->indent;
         $line_width += $self->indent;
      }

      @paragraph = grep { length($_) } @paragraph;
      while ( 
         @paragraph &&
            $line_width + 
            ( scalar(@line) * $space_width ) +
            $width{ $paragraph[0] } 
            < $self->w
      ) {
         $line_width += $width{ $paragraph[0] };
         push( @line, shift(@paragraph) );
      }

      # calculate the space width
      my ( $wordspace, $align );
      if ( $self->align eq 'fulljustify'
         or ( $self->align eq 'justify' and @paragraph ) 
      ) {
         if ( scalar(@line) == 1 ) {
            @line = split( //, $line[0] );
         }
         $wordspace = ( $self->w - $line_width ) / ( scalar(@line) - 1 );
         $align = 'justify';
      } else {
         # We've run out of words to fill a full line
         $align = ( $self->align eq 'justify' ) ? 'left' : $self->align; 
         $wordspace = $space_width;
      }
      $line_width += $wordspace * ( scalar(@line) - 1 );

      # If we want to justify this line, or if there are any markup tags
      # in here we'll have to split the line up word for word.
      if ( $align eq 'justify' or (grep /<.*>/, @line) ) {
         # TODO: #4 This loop is DOA for align 'right' and 'center' with any tags. 
         # FMCC Fix proposal
         if ( $align eq 'center' ) {
         	# Fix $xpos
         	$xpos += ( $self->w / 2 ) - ( $line_width / 2 );
         } elsif ( $align eq 'right' ) {
         	# Fix $xpos
         	$xpos += $self->w - $line_width;;         
         }
         # END FMCC Fix Proposal
         foreach my $word (@line) {
            if (($tag) = ($word =~ /<(.*?)>/)) {
               # warn "tag is $tag";
               if ($tag =~ /^href[a-z]?/) {
                  ($tag, $href) = ($tag =~ /(href[a-z]?)="(.*?)"/);
                  $current_content_text = $content_texts{$tag} if ref $content_texts{$tag};
               } elsif ($tag !~ /\//) {
                  $current_content_text = $content_texts{$tag};
               }
            }
                
            my $stripped = $word;
            $stripped =~ s/<.*?>//g;
            $debug && _debug("$tag 1", $xpos, $ypos, $stripped);
            $current_content_text->translate( $xpos, $ypos );

            if ($href) {
               $current_content_text->text($stripped);  # -underline => [2,.5]);

               # It would be nice if we could use -underline above, but it leaves gaps
               # between each word, which we don't like. So we'll have to draw our own line
               # that knows how and when to extend into the space between words.
               my $underline = $page->gfx;
               # $underline->strokecolor('black');
               $underline->linewidth(.5);
               $underline->move( $xpos, $ypos - 2);
               if ($word =~ /<\/href[a-z]?/) {
                  $underline->line( $xpos + $width{$word}, $ypos - 2);
               } else {
                  $underline->line( $xpos + $width{$word} + $wordspace, $ypos - 2);
               }
               $underline->stroke;

               # Add hyperlink
               my $ann = $page->annotation;
               $ann->rect($xpos, $ypos - 3, $xpos + $width{$word} + $wordspace, $ypos + 10);
               $ann->url($href);
            } else {
               $current_content_text->text($stripped);
            }

            unless ($width{$word}) {
               $debug && _debug("Can't find \$width{$word}");
               $width{$word} = 0;
            }
            $xpos += ( $width{$word} + $wordspace ) if (@line);

            if ($word =~ /\//) {
               if ($word =~ /\/href[a-z]?/) {
                  undef $href;
               }
               unless ($href) {
                  $current_content_text = $content_texts{default};
               }
            }
         }
         $endw = $self->w;
      } else {
         # calculate the left hand position of the line
         if ( $align eq 'right' ) {
            $xpos += $self->w - $line_width;
         } elsif ( $align eq 'center' ) {
            $xpos += ( $self->w / 2 ) - ( $line_width / 2 );
         }
         # render the line
         $debug && _debug("default 2", $xpos, $ypos, @line);
         $content_text->translate( $xpos, $ypos );
         $endw = $content_texts{default}->text( join( ' ', @line ) );
      }
      $ypos -= $self->lead;
      $first_line = 0;
   }

   # Don't yet know why we'd want to return @paragraphs...
   # unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
   #return ( $endw, $ypos );  # , join( "\n", @paragraphs ) )
   unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);
   my $overflow = join("\n",@paragraphs);
   return ( $endw, $ypos, $overflow);    #$overflow text returned to script
}


sub _debug{
   my ($msg, $xpos, $ypos, @line) = @_;
   printf("[%s|%d|%d] ", $msg, $xpos, $ypos);
   print join ' ', @line;
   print "\n";
}


=head2 garbledy_gook

Returns a scalar containing a paragraph of jibberish. Used by test scripts for 
demonstrations.

  my $jibberish = $tb->garbledy_gook(50);

The integer is the numer of jibberish words you want returned. Default is 100.

=cut

sub garbledy_gook {
   my ($self, $words) = @_;
   my $rval;
   $words ||= 100;
   for (1..$words) {
      for (1.. int(rand(10)) + 3) {
         $rval .= ('a'..'z')[ int(rand(26)) ];
      }
      $rval .= " ";
   }  
   chop $rval;
   return $rval;
}


# Applies defaults for you wherever you didn't explicitly set a different value.
sub _apply_defaults {
   my ($self) = @_;
   my %defaults = (
      x        => 20 / mm,
      y        => 238 / mm,
      w        => 175 / mm,
      h        => 220 / mm,
      lead     => 15 / pt,
      parspace => 0 / pt,
      align    => 'justify',
      fonts    => {},
   );
   foreach my $att (keys %defaults) {
      $self->$att($defaults{$att}) unless defined $self->$att;
   }

   # Create a new page inside our .pdf unless a page was provided.
   unless (defined $self->page) {
      $self->page($self->pdf->page);
   }

   # Use garbledy gook unless text was provided.
   unless (defined $self->text) {
      $self->text($self->garbledy_gook);
   }
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDF::TextBlock

Source code and bug reports on github: L<http://github.com/jhannah/pdf-textblock>

=head1 ACKNOWLEDGEMENTS

This module started from, and has grown on top of, Rick Measham's (aka Woosta) 
"Using PDF::API2" tutorial: http://rick.measham.id.au/pdf-api2/

=head1 COPYRIGHT & LICENSE

Copyright 2009-2021 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of PDF::TextBlock
