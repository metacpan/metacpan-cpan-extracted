#!/usr/bin/perl
# adapted from Rich Measham's tutorial http://rick.measham.id.au/pdf-api2/
# PDF::API2 changed to PDF::Builder, generalized image used, strip .pl from $0
# note the widespread use of convenient (inch, mm) dimensions rather than points
# some annotations added to explain code

use strict;
use warnings;

use PDF::Builder;

my $the_image =  # adjust as needed to find an image to show
      #'./Portrait.jpg'
      './examples/resources/aptfrontview.jpg'
      ;
my $output_name = $0;
$output_name =~ s/\.pl$//;  # in case (e.g., Windows), there's an extension

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

my ( $paragraph1, $paragraph2, $picture ) = get_data();

my $pdf = PDF::Builder->new( -file => "$output_name.pdf" );

my $page = $pdf->page;
$page->mediabox (105/mm, 148/mm); # 1/4 (1/2 each dimension) A4 paper size 
      # (normally 210/mm by 297/mm), presumably sized to just fill with 
      # available text. it also sets the coordinate system for all dimensions
      # used thereafter on this page.
$page->cropbox  (7.5/mm, 7.5/mm, 97.5/mm, 140.5/mm); # default: mediabox
      # this is the viewable area in a reader (90/mm by 133/mm) and
      # output (ink) is limited to this area (unless smaller bleedbox). this
      # page should be printed with a 7.5/mm margin all around the media. note
      # that use of the cropbox is NOT a good idea to define where you're going
      # to TRIM the paper after printing, as it will be difficult to avoid 
      # getting a little white edge. it's better to bleed just beyond any Trim
      # Box.
#$page->bleedbox(  5/mm,   5/mm,  100/mm,   143/mm); # default: cropbox
      # this is the limit of printing, including bleed-over, crop marks,
      # color alignment marks, and instructions to the printer.
#$page->trimbox(); # default: cropbox
      # this is where the finished page is cut, instructions to the printer 
      # may be outside the trimbox.
#$page->artbox  ( 10/mm,  10/mm,   95/mm,   138/mm); # default: cropbox
      # "meaniningful content" found within this box (should be kept, for
      # example, when printing N-up pages on one sheet).

# keep all available (opened) fonts in one place, with consistent access and
# naming. don't open anything that you don't plan to use, as it wastes space!
# note that only ttfont() can handle multibyte encodings such as UTF-8.
my %font = (
    Helvetica => {
        Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
    #   Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
    #   Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
    },
    Times => {
    #   Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
        Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
    #   Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
    },
);

# in real life, you would probably want this box to bleed over the trimbox
# line, to ensure that no white edge accidentally shows around it.
my $blue_box = $page->gfx;
$blue_box->fillcolor('darkblue');
# note that box extends 2.5/mm past the cropbox on three sides, giving another
# way to bleed to the edge.
$blue_box->rect( 5/mm, 125/mm, 95/mm, 18/mm );
$blue_box->fill;

# the red line should also extend past the trimbox line. like the blue_box,
# it extends 2.5/mm past the cropbox line on both ends, and bleeds to the edge.
my $red_line = $page->gfx;
$red_line->strokecolor('red');
$red_line->move( 5/mm, 125/mm );
$red_line->line( 100/mm, 125/mm );
$red_line->stroke;

# headline printed in blue box. note that text colors are normally given as
# fill color (glyphs are normally not stroked).
my $headline_text = $page->text;
$headline_text->font( $font{'Helvetica'}{'Bold'}, 18/pt );
$headline_text->fillcolor('white');
$headline_text->translate( 95/mm, 131/mm );
$headline_text->text_right('USING PDF::Builder');

my $background = $page->gfx;
$background->strokecolor('lightgrey');
$background->circle( 20/mm, 45/mm, 45/mm );
$background->circle( 18/mm, 48/mm, 43/mm );
$background->circle( 19/mm, 40/mm, 46/mm );
$background->stroke;

my $left_column_text = $page->text;
$left_column_text->font( $font{'Times'}{'Roman'}, 6/pt );
$left_column_text->fillcolor('black');
my ( $endw, $ypos, $paragraph ) = text_block(
    $left_column_text,
    $paragraph1,
    -x        => 10/mm,
    -y        => 119/mm,
    -w        => 41.5/mm,
    -h        => 110/mm - 7/pt,
    -lead     => 7/pt,
    -parspace => 0/pt,
    -align    => 'justify',
);

$left_column_text->font( $font{'Helvetica'}{'Bold'}, 6/pt );
$left_column_text->fillcolor('darkblue');
( $endw, $ypos, $paragraph ) = text_block(
    $left_column_text,
    'Enim eugiamc ommodolor sendre feum zzrit at. Ut prat. Ut lum quisi.',
    -x => 10/mm,
    -y => $ypos - 7/pt,
    -w => 41.5/mm,
    -h => 110/mm - ( 119/mm - $ypos ),
    -lead     => 7/pt,
    -parspace => 0/pt,
    -align    => 'center',
);

$left_column_text->font( $font{'Times'}{'Roman'}, 6/pt );
$left_column_text->fillcolor('black');
( $endw, $ypos, $paragraph ) = text_block(
    $left_column_text,
    $paragraph2,
    -x => 10/mm,
    -y => $ypos,
    -w => 41.5/mm,
    -h => 110/mm - ( 119/mm - $ypos ),
    -lead     => 7/pt,
    -parspace => 0/pt,
    -align    => 'justify',
);

my $photo = $page->gfx;
die("Unable to find image file: $!") unless -e $picture;
my $photo_file = $pdf->image_jpeg($picture);
$photo->image( $photo_file, 54/mm, 66/mm, 41/mm, 55/mm );

my $right_column_text = $page->text;
$right_column_text->font( $font{'Times'}{'Roman'}, 6/pt );
$right_column_text->fillcolor('black');
( $endw, $ypos, $paragraph ) = text_block(
    $right_column_text,
    $paragraph,
    -x        => 54/mm,
    -y        => 62/mm,
    -w        => 41.5/mm,
    -h        => 54/mm,
    -lead     => 7/pt,
    -parspace => 0/pt,
    -align    => 'justify',
    -hang     => "\xB7  ",
);

$pdf->save;
$pdf->end();

sub text_block {

    my $text_object = shift;
    my $text        = shift;

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

    $ypos = $arg{'-y'};
    my @paragraph = split( / /, shift(@paragraphs) );

    my $first_line      = 1;
    my $first_paragraph = 1;

    # while we can add another line

    while ( $ypos >= $arg{'-y'} - $arg{'-h'} + $arg{'-lead'} ) {

        unless (@paragraph) {
            last unless scalar @paragraphs;

            @paragraph = split( / /, shift(@paragraphs) );

            $ypos -= $arg{'-parspace'} if $arg{'-parspace'};
            last unless $ypos >= $arg{'-y'} - $arg{'-h'};

            $first_line      = 1;
            $first_paragraph = 0;
        }

        my $xpos = $arg{'-x'};

        # while there's room on the line, add another word
        my @line = ();

        my $line_width = 0;
        if ( $first_line && exists $arg{'-hang'} ) {

            my $hang_width = $text_object->advancewidth( $arg{'-hang'} );

            $text_object->translate( $xpos, $ypos );
            $text_object->text( $arg{'-hang'} );

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

                $text_object->translate( $xpos, $ypos );
                $text_object->text($word);

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
            $text_object->translate( $xpos, $ypos );

            $endw = $text_object->text( join( ' ', @line ) );

        }
        $ypos -= $arg{'-lead'};
        $first_line = 0;

    }
    unshift( @paragraphs, join( ' ', @paragraph ) ) if scalar(@paragraph);

    return ( $endw, $ypos, join( "\n", @paragraphs ) )

}

### SAVE ROOM AT THE TOP ###
sub get_data {
    return (
qq|Perci ent ulluptat vel eum zzriure feuguero core consenis adignim irilluptat praessit la con henit velis dio ex enim ex ex euguercilit il enismol eseniam, suscing essequis nit iliquip erci blam dolutpatisi.
Orpero do odipit ercilis ad er augait ing ex elit autatio od minisis amconsequam, quis am il do consenim esequi eui blamcorer adiat. Ut prat la facip ercip eugiamconsed tio do exero ea consequis do odolor il dolut wisim adit, susciniscing et adit num num vel ip ercilit alismolorem zzril ute dolendre ming eu feui bla feugait il illa facin eu feugiam conseniam eliquisl et luptat la feu feugait, volore euguerc incillu msandigna feuipisl iriuscilit velit wisl utem veros ad min velit laor iuscilit veliquis ad tie endignim dignisl et, qui bla feugue mod enibh esendiam, si blaor si blaore te min vel utpat nonsequ issequis dolorperosto dolobore ex erit, vel in utating etum ad dolutatet la feugiatue mod euisci blandre tat iurem eum velit prat nosting essim ver aliscil dolortie cor alisit wisl delesti sciduisci ting eu feu facidunt autat. Duipis amcommy non er sit, commy numsand ionsequam, commy num alisim euis dio eu faciduisit ate moloreet, quam zzrillaore magnit eum dolor ipsum dunt dolor sequatie dolor iustrud te molum dolore velit la faccum zzriuscil utpat irit nummod magna alis eu faccum inibh erosto ea ad magniamet vel esto dipsusto elesting eugiam, commolobore deliquat praessenim et, vel ut et nibh et adit lortisi.|,

qq|It augait ate magniametum irit, venim doloreet augiamet ilit alis nonse dolore delessit volor susto od ming eugiam voloborem ip ea faciduisis alit, vent nim nulput utat endre dolum quissit atem nim dolorperci tat dunt veliquat ipis acip elenit lum dunt luptat. Ut luptat nulla feu facin hent dolobore vulput augait, quamet vent non utpat nulput nonsed doloreetum dio estis eum aut accummy nos nisi.
Orpero do odipit ercilis ad er augait ing ex elit autatio od minisis amconsequam, quis am il do consenim esequi eui blamcorer adiat. Ut prat la facip ercip eugiamconsed tio do exero ea consequis do odolor il dolut wisim adit, susciniscing et adit num num vel ip ercilit alismolorem zzril ute dolendre ming eu feui bla feugait il illa facin eu feugiam.
Conseniam eliquisl et luptat la feu feugait, volore euguerc incillu msandigna feuipisl iriuscilit velit wisl utem veros ad min velit laor iuscilit veliquis ad tie endignim dignisl et, qui bla feugue mod enibh esendiam, si blaor si blaore te min vel utpat nonsequ issequis dolorperosto.
Dolobore ex erit, vel in utating etum ad dolutatet la feugiatue mod euisci blandre tat iurem eum velit prat nosting essim ver aliscil dolortie cor alisit wisl delesti sciduisci ting eu feu facidunt autat. Duipis amcommy non er sit, commy numsand ionsequam.|,

        $the_image
    );
}
