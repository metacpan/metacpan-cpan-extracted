#!/usr/bin/perl -w
use strict;
use warnings;
use Carp 'verbose'; local $SIG{__DIE__} = sub { Carp::confess(@_) }; use Data::Dumper;
use PDF::Table;
# -------------
# -A or -B on command line to select preferred library (if available)
# then look for PDFpref file and read A or B forms
my ($PDFpref, $rcA, $rcB); # which is available?
my $prefFile = "./PDFpref";
my $prefDefault = "B"; # PDF::Builder default if no prefFile, or both installed
if (@ARGV) {
    # A or -A argument: set PDFpref to A else B
    if ($ARGV[0] =~ m/^-?([AB])/i) {
	$PDFpref = uc($1);
    } else {
	print STDERR "Unknown command line flag $ARGV[0] ignored.\n";
    }
}
if (!defined $PDFpref) {
    if (-f $prefFile && -r $prefFile) {
        open my $FH, '<', $prefFile or die "error opening $prefFile: $!\n";
        $PDFpref = <$FH>;
        if      ($PDFpref =~ m/^A/i) {
	    # something starting with A, assume want PDF::API2
	    $PDFpref = 'A';
        } elsif ($PDFpref =~ m/^B/i) {
	    # something starting with B, assume want PDF::Builder
	    $PDFpref = 'B';
        } elsif ($PDFpref =~ m/^PDF:{1,2}A/i) {
	    # something starting with PDF:A or PDF::A, assume want PDF::API2
	    $PDFpref = 'A';
        } elsif ($PDFpref =~ m/^PDF:{1,2}B/i) {
	    # something starting with PDF:B or PDF::B, assume want PDF::Builder
	    $PDFpref = 'B';
        } else {
	    print STDERR "Don't see A... or B..., default to $prefDefault\n";
	    $PDFpref = $prefDefault;
        }
        close $FH;
    } else {
        # no preference expressed, default to PDF::Builder
        print STDERR "No preference file found, so default to $prefDefault\n";
        $PDFpref = $prefDefault;
    }
}
foreach (1 .. 2) {
    if ($PDFpref eq 'A') { # A(PI2) preferred
        $rcA = eval {
            require PDF::API2;
            1;
        };
        if (!defined $rcA) { $rcA = 0; } # else is 1;
        if ($rcA) { $rcB = 0; last; }
	$PDFpref = 'B';
    } 
    if ($PDFpref eq 'B') { # B(uilder) preferred
        $rcB = eval {
            require PDF::Builder;
            1;
        };
        if (!defined $rcB) { $rcB = 0; } # else is 1;
	if ($rcB) { $rcA = 0; last; }
	$PDFpref = 'A';
    }
}
if (!$rcA && !$rcB) {
    die "Neither PDF::API2 nor PDF::Builder is installed!\n";
}
# -------------

our $VERSION = '1.003'; # VERSION
our $LAST_UPDATE = '1.002'; # manually update whenever code is changed

my $outfile = $0;
$outfile =~ s/\.pl$/.pdf/;

# TTF font to use. customize path per your local system.
# DejaVuSans.ttf also needs to exist in this directory
my $dir = 
# '/usr/share/fonts/truetype/dejavu/';
  '/Windows/Fonts/';

my ( $pdf, $page, $font, $ttfont, $text, $pdftable, $left_edge_of_table, $try );
use utf8; 
$try = " 
accents:         á é í ó ú  Á É Í Ó Ú 
Spanish (tilde): ñ Ñ   ¿ ¡
German (umlaut): ä ö ü ß Ö Ä Ü 
Cyrillic:        ѐ Ѐ Ѡ ѡ Ѣ 
Greek:           α β γ δ Γ Δ 
Armenian:        Ա Բ Գ Դ Ե 
Hebrew:          א ב ג ד 
Arabic:          ر     ش س ذ      
Mono:            iI lL zero=0 one=1
Latin-1 Supplement:  ° À Ð à ð
Latin-Extended A:    Ā Đ Ġ 
Latin-Extended B:    ƀ Ɛ Ơ
Cyrillic Supplement: Ԃ Ԡ Ԓ  
http://dejavu.sourceforge.net/samples/DejaVuSans.pdf

"; no utf8; 

# https://github.com/dejavu-fonts/dejavu-fonts
#   /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf  
# You can save custom fonts in the folder ~/.fonts
# $ sudo apt update && sudo apt -y install font-manager
# https://dejavu-fonts.github.io/Samples.html 

make_another('010_fonts-default.pdf', '', $try , 'logo.png' );
use utf8; my $try_utf8 = $try; 
make_another('010_fonts-use_utf.pdf', 'DejaVuSans', $try_utf8 , 'logo.png' );
no utf8; my $no_utf8 = $try; 
make_another('010_fonts-no_utf8.pdf', 'DejaVuSans', $no_utf8  , 'logo.png' );
# make_another('010_fonts-default.pdf', 'DejaVuSans', $try , 'logo.png' );


sub make_another {
    my ($file, $passed_font_name, $passed_text, $passed_image_name ) = @_ ; 

    print "Passed \$file = '$file', \$font_name = '$passed_font_name', \$image_name = '$passed_image_name' \n"; 
    print "\n INLINE! 
accents:         á é í ó ú  Á É Í Ó Ú 
Spanish (tilde): ñ Ñ   ¿ ¡
German (umlaut): ä ö ü ß Ö Ä Ü 
Cyrillic:        ѐ Ѐ Ѡ ѡ Ѣ 
Greek:           α β γ δ Γ Δ 
Armenian:        Ա Բ Գ Դ Ե 
Hebrew:          א ב ג ד 
Arabic:          ر     ش س ذ      
Mono:            iI lL zero=0 one=1
Latin-1 Supplement:  ° À Ð à ð
Latin-Extended A:    Ā Đ Ġ 
Latin-Extended B:    ƀ Ɛ Ơ
Cyrillic Supplement: Ԃ Ԡ Ԓ  
http://dejavu.sourceforge.net/samples/DejaVuSans.pdf


    ";
    # Create a blank PDF file
    # -------------
    my $pdf;
    if ($rcA) {
        print STDERR "Using PDF::API2 library\n";
        $pdf      = PDF::API2->new();
    } else {
        print STDERR "Using PDF::Builder library\n";
        $pdf      = PDF::Builder->new();
    }
    # -------------
    $pdftable = PDF::Table->new();
    # Add a blank page
    $page = $pdf->page();
    # Set the page size
    # my $page->mediabox('Letter');
    # Add a built-in font to the PDF
        # Add some text to the page
    $text = $page->text();
    $font = $pdf->corefont('Helvetica-Bold' ); # default to Latin-1 encoding
    $text->font( $font, 14 );   $text->translate( 50, 700 );
    $text->text("In core font: $passed_text\n");
    print "$dir$passed_font_name.ttf\n";
    my $ttfont;
    if ($passed_font_name eq '') {
	$ttfont =  $pdf->ttfont($dir.'DejaVuSans'.'.ttf');
    } else {
	$ttfont =  $pdf->ttfont($dir.$passed_font_name.'.ttf');
    }
    $text->font( $ttfont, 14 );   $text->translate( 50, 650 );
    $text->text("In true type font: $passed_text\n");
    $text->translate( 50, 600 );
    $text->text("In true type font: INLINE!
accents:         á é í ó ú  Á É Í Ó Ú 
Spanish (tilde): ñ Ñ   ¿ ¡
German (umlaut): ä ö ü ß Ö Ä Ü 
Cyrillic:        ѐ Ѐ Ѡ ѡ Ѣ 
Greek:           α β γ δ Γ Δ 
Armenian:        Ա Բ Գ Դ Ե 
Hebrew:          א ב ג ד 
Arabic:          ر     ش س ذ      
Mono:            iI lL zero=0 one=1
Latin-1 Supplement:  ° À Ð à ð
Latin-Extended A:    Ā Đ Ġ 
Latin-Extended B:    ƀ Ɛ Ơ
Cyrillic Supplement: Ԃ Ԡ Ԓ  
http://dejavu.sourceforge.net/samples/DejaVuSans.pdf
 
    \n");

    my $some_data = [ ['core font: '. $passed_text], ];
    $left_edge_of_table = 50;
#    x                    
#    w                    
#    start_y              
#    start_h              
#    next_y               
#    next_h               
#    lead                 
#    padding              
#    padding_right        
#    padding_left         
#    padding_top          
#    padding_bottom       
#    background_color     
#    background_color_odd 
#    background_color_even
#    border               
#    border_color         
#    horizontal_borders   
#    vertical_borders     
#    font                 
#    font_size            
#    font_underline       
#    font_color           
#    font_color_even      
#    font_color_odd       
#    background_color_odd 
#    background_color_even
#    row_height           
#    new_page_func        
#    header_props         
#    column_props         
#    cell_props           
#    max_word_length      
#    cell_render_hook     
#    default_text
#
    # build the table layout
    $pdftable->table(
        # required params
        $pdf, $page, $some_data, x  => $left_edge_of_table, w  => 500, start_y => 500, start_h => 300,
        # some optional params
       font => $font , 
    #     next_y        => 750,
    #    next_h        => 500,
     #   padding       => 5,
      #  padding_right => 10,
#     background_color_odd  => "gray",
#     background_color_even => "lightblue", # cell background color for even rows
    );
    $some_data = [ ['true type font: '. $passed_text], ];
    $left_edge_of_table = 50;
    if ($passed_font_name) {
        $pdftable->table( $pdf, $page, $some_data, x  => $left_edge_of_table, w  => 500, start_y => 500, start_h => 300, font => $ttfont , );
    } else {  # go to default font 
        $pdftable->table( $pdf, $page, $some_data, x  => $left_edge_of_table, w  => 500, start_y => 500, start_h => 300, );
    }
   # Save the PDF
   $pdf->saveas($file);

   return;
}
