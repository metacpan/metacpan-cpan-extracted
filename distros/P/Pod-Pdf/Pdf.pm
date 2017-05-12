package Pod::Pdf;

# version 1.2 26 May 2000
# © Alan Fry <ajf@afco.demon.co.uk>

################################################################################
#  24-May-2000 -- v1.2  File input methods extended to STDIN and options (AJF) #
#  23-May-2000 -- v1.2  Variable initialisations into define_variables() (AJF) #
#  22-May-2000 -- v1.2  Opening statements put into pod2pdf()      (Axel Rose) #
#  18-Apr-2000 -- v1.1  File::Basename routines added and ToC revised          #
#  09-Apr-2000 -- v1.1  Text formatting routines revised                       #
#  09-Apr-2000 -- v1.1  URI Link implemented                                   #
################################################################################

use File::Basename;
use Getopt::Long;
use Exporter;
use strict;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw( Exporter );
@EXPORT = qw( pod2pdf );
$VERSION = "1.2";

my $in_file  = '';                       # Full path 'pod' file name
my $title    = '';                       # 'pod' leaf file-name
my $dir = '';                            # path to '$title'
my $out_file = '';                       # Full path 'pdf' output file name
my $buf = '';                            # Occasional buffer string

my %HTML;                                # HTML escapes
my @wx;                                  # Font metrics arrays

my $x_size = 595;                        # default page width (pixels)
my $y_size = 842;                        # default page height (pixels)
my $verbose = 0;                         # error message flag

my %fontstyle;                           # definitions for 'link' and 'files'
my %fontdef;                             # definition of hash key names
my %setStyles;                           # definition of POD element styles
my %colorstyle;                          # definition of POD element colours
my @Roman;                               # Arabic to Roman numeral conversion 

my $f_pos = 0;                           # position in PDF file
my $obj   = 0;                           # PDF object number
my @o_loc = ();                          # PDF object's file position
my $resources = '';                      # Resources object number
my %o_rec = ();                          # Record of named objects
my @Kids = ();                           # Page object numbers of document
my @tocKids = ();                        # Page object numbers of ToC
my @coverKids = ();                      # Page object numbers for cover page
my @Fonts = ();                          # List of fonts used on a page
my $stream_start = 0;                    # Stream start position in file
my $stream_end = 0;                      # Stream_end position in file
my $stream_length = 0;                   # Stream length
my %fonts_used = ();                     # List of fonts actually used on a page
my @levels = ();                         # List of outline levels
my @ol = ();                             # List of outline parameters
my $no = 0;                              # Index of outline entries
my $i = 0;                               # Occasional index
my $h2 = 0;                              # Flag set after head2 level

my $start_time = 0;                      # Time at start of process
my $finish_time = 0;                     # Time at end of process
my $more = 0;                            # Flag indicating more to come from pod file
my $in_text = 0;                         # Flag set while processing a text block
my $in_pod = 0;                          # Flag set when in a POD section
my $pod_found = 0;                       # Flag set if POD text found
my $in_verbatim = 0;                     # Flag set while processing a verbatim block
my $in_tab = 0;                          # Flag set after a tab
my $in_heading = 0;                      # Heading flag
my $was_item = 0;                        # Last heading was an '=item'
my $bl = 0;                              # blank line flag
my $zlf = 1;                             # zero line feed flag
my $for = 0;                             # '=for' block flag
my $special = 0;                         # '=begin' block flag
my $j =  0;                              # scratch-pad index
my $p =  0;                              # scratch-pad indeces
my @jt = ();                             # scratch-pad pointers
my @pt = ();                             # scratch-pad pointers
my @scratch_pad = ();                    # scratch pad
my @sc = ();			                 # colour scratch-pad
my $sp = 1;                              # Starting page number
my $lp = 0;                              # Last page number of document section
my $page = 1;                            # Current page number (start at 1)
my $start_page = 1;                      # start page number
my $ypos = 0;                            # Current height on page (pixels)
my $xpos = 0;                            # Current line position
my $yrem = 0;                            # Height currently remaining on page
my $inside_margin = 72;                  # Inside page margin
my $outside_margin = 72;                 # Outside page margin
my $left_margin = 72;                    # Left margin
my $right_margin = 72;                   # Right margin
my $end = 0;                             # Position of end of line
my $top_margin = 72;                     # top page margin for body text
my $bottom_margin = 62;                  # bottom page margin for body text 
my $top_bar = 50;                        # distance from top of page to header bar
my $bottom_bar = 50;                     # distance from bottom of page to footer bar
my $left_indent = 30;                    # Amount by which to indent everything but H1 and H2
my $leading = 1.2;                       # multiply by current fontsize to get line spacing
my $paragraph_space = 0.5;               # multiply by line spacing to get space between paragaphs            
my $tab_per_char = 6;                    # points per character multiplier for tab stops
my $heading_lift = 0.2;                  # multiply by line spacing to get extra space under heading            
my $index_indent = 20;                   # Amount to indent for every new level of ToC
my $LF = 0;                              # Line feed == $leading * $fs;
my $uH = 0;                              # Heading lift == $LF * $heading_lift;
my $WS = 0;                              # White Space == $LF * $paragraph_space;
my $cLM = 0;                             # Current left margin on page
my $set = 0;                             # Tab stop number
my @ov = ();                             # Tab position array
my $indent = 0,                          # Current tab indent (in points)
my $lineleng = 0;                        # Current linelength in points
my $line = '';                           # String
my $k = 0;                               # Line length error per space
my $k_max = 5;                           # if $k > $k_max the line is not justified
my $spaces = 0;                          # Count of spaces in line
my $fs = 0;                              # Font size
my @lk = ();                             # List of links
my $in_link = 0;                         # Processing link (flag)
my $link_string = '';                    # Link string
my $wordleng = 0;                        # Word length (used in sub 'just')
my $tab_str = 0;                         # Flag for string containing a tab character
my @annot = ();                          # List of 'link' annotations


my $current_color = 0;
my $date = '';                           # Footer date string
my $h_str = 'pod2pdf';                   # Inside string for header
my $section = '';                        # Section type: 'doc', 'cat', 'ind', etc.

sub pod2pdf {
	local @ARGV = @_;
	unless ( @ARGV && $ARGV[0] ) { die "no input, no output!\n" }
	
	parse_command_line();

	unless ($ARGV[0]) {
	    $in_file = '-' unless $in_file
	}
	else {
	    $in_file = $ARGV[0]
	}

	$title = basename($in_file);
	$dir   = dirname($in_file);

	$title = pdfEscape($title);
	$out_file = $in_file.'.pdf';
	$date = page_date();

    define_variables();

	#$start_time = (times)[0];  # fails on Windows perl 5.003
	$start_time = time;

	pdfOpen($out_file);
	pdfOutline(0, 'Table of Contents', undef, $y_size);

	$section = 'doc';
	my $in_pod = 0;
	my $pod_found = 0;
	readFile($in_file);
	unless ($page % 2) {
	    pageHeader($h_str, $title);
	    pageFooter();
	    $lp++;
	}

	$section = 'toc';
	buildTOC();

	$section = 'cov';
	coverPage();

	outlineTree();
	pdfTrailer();

	#my $finish = (times)[0];
	my $finish = time;
	printf( STDERR "PDF generation time = %4.2f sec)\n", $finish - $start_time ) if $verbose;
	exit 0;

}

sub parse_command_line {
	my( $opt_paper, $opt_help, $result);
	my $usage = qq{
	$0 
	[ --help --verbose <1|2 --paper <usletter> --podfile <file> ] <file>
	
	--help
	    displays this explanation of correct usage
	    
	--vebose <1|2>
	    regulates the volume of progress comments: argument must be 1 or 2
	    
	--podfile <file>
	    supplies the input file to process as an explicit parameter. The
	    input file may also be supplied from STDIN or from the command
	    line as the array element $ARGV[0].
	    
	Further information can be found in the POD section of Pod.pm. Enter:
	    perl -e "use Pod::Pdf; pod2pdf('<your_library_path>/Pod/Pdf.pm')"
	to get the POD in PDF format :)

	};
	
	$result = GetOptions(
		'paper:s'	=> \$opt_paper,
		'podfile:s' => \$in_file,
		'verbose=i' => \$verbose,
		'help'      => sub { print STDERR $usage; exit(0) }
		);

	if ((defined $opt_paper) =~ /usletter/i) {$x_size = 612; $y_size = 792}
	unless ($result or $opt_help) { print STDERR $usage; exit(0) }
}

sub define_variables {

	%setStyles = (
	                  'H1'           => [ 12, 'Helvetica', 'Bold'     ],
	                  'H2'           => [ 10, 'Helvetica', 'Bold'     ],
	                  'H3'           => [ 10, 'Helvetica', 'Regular'  ],
	                  'Body'         => [ 10, 'Times',     'Regular'  ],
	                  'Verbatim'     => [ 10, 'Courier',   'Regular'  ],
	                  'header'       => [ 10, 'Helvetica', 'Bold'     ],
	                  'footer'       => [ 10, 'Helvetica', 'Bold'     ],
	                  'ToC'          => [ 24, 'Helvetica', 'Regular'  ],
	                  'coverTitle'   => [ 48, 'Times',     'Italic'   ],
	              );
	              
	%fontstyle = (
		              'link' => 2,
		              'file' => 3,
		            );
		      
	%colorstyle = (
		              'link'    => '0 0 0.8 rg',
		              'text'    => '0 g',
		              'special' => '0.8 0 0 rg'
		             );

	%fontdef = (
	                '/F00'  =>  'Times-Roman',
	                '/F01'  =>  'Times-Bold',
	                '/F02'  =>  'Times-Italic',
	                '/F03'  =>  'Times-BoldItalic',
	                '/F10'  =>  'Courier',
	                '/F11'  =>  'Courier-Bold',
	                '/F12'  =>  'Courier-Oblique',
	                '/F13'  =>  'Courier-BoldOblique',
	                '/F20'  =>  'Helvetica',
	                '/F21'  =>  'Helvetica-Bold',
	                '/F22'  =>  'Helvetica-Oblique',
	                '/F23'  =>  'Helvetica-BoldOblique'
	             );
	             
	@Roman = qw(0 i ii iii iv v vi vii viii ix x
	               xi xii xiii xiv xv xvi xvii xviii xix xx
	               xxi xxii xxiii xxiv xxv xxvi xxvii xxviii xxix xxx
	               xxxi xxxii xxxiii xxxiv xxxv xxxvi xxxvii xxxviii xxxix xl);

	&ESC;                           # initialise escapes
	afm();                          # Initialise fonts
}

sub readFile {

    if( !open(IN, "<$in_file") ) {
        print STDERR "WARNING: Could not read file $in_file.\n";
        unlink $out_file;
        exit 0;
    }
    while(<IN>) {
        if (/^=include\s*(.*)/) {
            $in_pod = 0;
            if(!open(INCLUDE, "$dir:$1")) {
                print STDERR "WARNING: Could not read file $in_file.\n";
                unlink $out_file;
                exit 0
            }
            while(<INCLUDE>) {
                parsePod() if defined $_;
            }
        } 
        parsePod() if defined $_;
    }

    close IN;
    if( !$pod_found ) {
        print STDERR "SKIPPING FILE: No pod text found in $in_file\n" if $verbose;
        unlink $out_file;
        return 0;
    }

    $more = 0;
    &just("\n");
    $lp = $page;
    &pageFooter;
}

my $m;
sub parsePod {
    my $store = '';

    if ( /^=(back|over|head|item|pod)/ ) {
        $in_pod = 1;
        if( !$pod_found ) {
            $pod_found = 1;
            _initPod($in_file);
        }
    }

    return if !$pod_found;
    if ( /^=(cut)/ ) {$in_pod = 0 };                    
    if ( !$in_pod ) { return }                                    # Skip non-pod text.
    if ( /^=(pod)/ ) { return };
    if ( /^=(begin)/ ) { $special = 1; return }
    if ( /^=(for)/ ) { $special = 1; $for = 2; return }
    if ( /^=end/ ) { $special = 0; return }
    if ( /^\s*$/ ) { $more = 0 } else { $more = 1 }
    if ( /^=over.*/ ) { &IND($_); return }                       # indent
    if ( /^=back/ ) { &BAK; return }                             # cancel indent
    if ( /^\s*\n/ ) { &BL; return }                              # blank line
    if ( /(^\s+.*)$/ and !$in_text) { &VRB($1); return }         # verbatim txt
    if ( /S</g ) { $_ = &HSP($_) }                               # non-breaking-spaces
   #$_ =~ s/"(.*?)"/\252$1\272/g;                                # convert double quotes
   #s/([&\$]\S*)/C<$1>/g; 	                                     # convert $XYZ or &XYZ to code
   #s/(\S*\(\))/C<$1>/g;                                         # convert XYZ() to code
    s/\\([2-3][0-7][0-7])/chr(oct($1))/ge;                       #convert octal to character
    s/\'([^\s>\.\)])/\140$1/g;                                   #convert single quotes
    s/Z<.*?>//;                                                  #zero-width character
    s/--/\217/g;                                                 #convert -- to emdash
    s/B</\002/g;                                                 #encode 'BOLD'
    s/I</\003/g;                                                 #encode 'ITALIC'
    s/C</\004/g;                                                 #encode constant-pitch font
    s/F</\005/g;                                                 #encode style for 'FILE'
    s/L</\006/g;                                                 #encode style for 'LINK'
    if ($_ =~ /(L<[^>]*)\n/) { $store .= $` . $1 . " "; return }
    $_ = $store.$_; $store = "";                                 #mend broken links (if any)
   #if (/L</) { $_ = redoL($_) }                                 #encode style for 'LINK'
    s/E<(.*?)>/$HTML{$1}/g;                                      #escape HTML entities
    s/>/\001/g;                                                  #cancel last encoding
    s/(<.*?)\001/$1>/g;                                          #match opening < (if any)
    if ( /^=head1\s+(.*)$/) { &H1($1); return  }                 #heading 1
    if ( /^=head2\s+(.*)$/) { &H2($1); return }                  #heading 2
    if ( /^=item\s+(.*)$/) { &H3($1); return }                   #item heading
    if ( /(^\s+.*)$/ ) { &TAB($1); return }                      #tabbed text txt
    #$in_text = 0;
    chomp $_; &TXT($_);                                          #anything else must be text
}

sub _initPod {
    my $ifname = shift;    
    print STDERR "Processing pod file $ifname\n" if $verbose;

    $sp = $page;
   
    $in_verbatim = 0;                    # verbatim block flag (set to 1 in verbatim block)
    $in_text = 0;                        # text block flag (set to 1 in text block)
    $in_tab = 0;                         # set after an indented line in a text-block
    $bl = 0;                             # blank line flag 
    $zlf = 1;                            # zero line feed flag
    $more = 0;                           # more to come (from file)
    $j = $p = 0;                         # scratch-pad indeces
    $jt[$j] = $pt[$p] = [0, 0];          # scratch-pad pointers
    $sc[$p] = 'text';			         # scratch-pad color
    setColor();
    $ypos = $y_size - $top_margin;       # initialise Y position
    &Init;                               # initialise X margin position and tab settings
    $yrem = $ypos;

    pageHeader($h_str, $title);
}

sub H1 {
    my ($str) = @_;
    $ypos -= $WS;
    if( $ypos <= ( $bottom_margin + 26 ) ) {
        pageFooter();
        pageHeader($h_str, $title);
        $zlf = 1;
        $bl = 0;
    } 
    setFont('H1');
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = 'text';
    setColor();
    &Init;
    $xpos = $left_margin;
    pdfOutline(1, $str, $page, $ypos+$LF);
    &just($str);
    $in_verbatim = $in_text = $in_tab = $bl = 0;
    $zlf = 1;
    $in_heading = 1;
}

sub H2 {
    my ($str) = @_;
    $ypos -= $WS;
    $bl = $in_verbatim = $in_text = $in_tab = 0; $zlf = 1;
    if ($ypos <= ( $bottom_margin + 24 )) {
        pageFooter();
        pageHeader($h_str, $title);
        $zlf = 1;
        $bl = 0;
    }
    setFont('H2');
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = 'text';
    setColor();
    &Init;
    $xpos = $left_margin;
    pdfOutline(2, $str, $page, $ypos+$LF);
    $in_heading = 1;
    &just($str); 
}

sub H3 {
    $ypos -= $uH;
    my ($str) = @_;
    if ($in_verbatim or $in_text ) { $ypos -= $WS; }

    $str =~ s/^\*\s*(.*)/\007$1/;	# bullet
    if ($ypos <= $bottom_margin ) {
        pageFooter();
        pageHeader($h_str, $title);
        $zlf = 1;
        $bl = 0;
    } 
    setFont('H3');
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = 'text';
    setColor();
    $xpos = $cLM;
    pdfOutline(3, $str, $page, $ypos+$LF);
    $in_verbatim = $in_text = $in_tab = $bl = 0;
    $in_heading = 1;
    $was_item = 1;
    just($str);
    ZLF($str);
}

sub IND {
    my $tab;
    if( $_[0] =~ /^=over\s*(\d+)/ ) {
        $tab = $1;
    } else {
        $tab = 4;
    }
    if ($set) { $cLM += $tab_per_char * $ov[$set] }
    ++$set;                               # tab stop number (1, 2, 3, ...)
    $ov[$set] = $tab;                     # tab indent for tab stop $set (in characters)
    $indent = $tab_per_char * $ov[$set];  # current tab indent (in points)
}

sub BAK {
    if (--$set < 0) { $set = 0 }
if (!defined $ov[$set]) { $ov[$set] = 0 }
    $cLM -= $tab_per_char * $ov[$set];
    if ($cLM < $left_margin + $left_indent ) { $cLM = $left_margin + $left_indent }
    $indent = 6 * $ov[$set];
}

sub Init {
    $set = 0;                             # tab position number
    @ov = ();                             # tab position array
    $cLM = $left_margin + $left_indent;   # current left margin (in points)
    $indent = 0;                          # current indent (in points)
}

sub VRB {
    my ($str) = @_;
    just ("\n");
    setFont('Verbatim') unless $in_verbatim;
    if ($ypos <= ($bottom_margin + $LF) and $more) {
        pageFooter();
        pageHeader($h_str, $title);
        $bl = 0;
        prt("/F$pt[$p][0]$pt[$p][1] $fs Tf\n");
        $fonts_used{"/F$pt[$p][0]$pt[$p][1]"} = ' ';
        @scratch_pad = ($pt[$p][0], $pt[$p][1]);
    }
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = 'text';
    setColor();
    $xpos = $cLM + $indent;
    if ($in_verbatim) { $ypos -= $LF }
    elsif (!$in_verbatim and $bl) { $ypos -= $WS }
    $in_verbatim = 1;
    $in_text = $in_tab = $bl = 0;
    $zlf = 1;
    just($str);
}

sub TAB { 
    my ($str) = @_;
    &just ("\n");
    setFont('Body') unless $in_tab;
    if ($ypos <= ($bottom_margin + $LF) and $more) {
        pageFooter();
        pageHeader($h_str, $title);
        $bl = 0;
        prt("/F$pt[$p][0]$pt[$p][1] $fs Tf\n");
        $fonts_used{"/F$pt[$p][0]$pt[$p][1]"} = ' ';
        @scratch_pad = ($pt[$p][0], $pt[$p][1]);
    }
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = 'text';
    setColor();
    $xpos = $cLM + $indent;
    if ($in_heading) { $ypos -= $uH; $in_heading = 0 }
    if ($bl) { $ypos -= $WS } 
    else { $ypos -= $LF }
    $bl = 0;
    $zlf = 1;
    $in_tab = 1;
    &just($str); 
    &just("\n");
}

sub TXT {
    my ($txt) = @_;
    
    if ($in_verbatim) { $ypos -= $LF; $in_verbatim = 0; }
    if ($in_tab) { $in_text = $in_tab = 0 }
    if ($in_text)  { just($txt); return }
    if ($in_heading) { just($txt); return }
    
    $bl = $in_verbatim = 0;
    
    if ($ypos <= ( $bottom_margin + $LF ) and $more and $zlf ) {
        pageFooter();
        pageHeader($h_str, $title);
        $bl = 0;
    }
    setFont('Body');
    $j = $p = 0; $jt[0] = $pt[0] = [@scratch_pad];
    $sc[$p] = $special ? 'special' : 'text';
    setColor();
	$xpos = $cLM + $indent;
    $in_text = 1;
    &just($txt);
} 

sub BL {
    return if $bl;
    just("\n");
    $ypos -= $LF;
    if ($for) { # '=for' block
        $for--;
        $for = $for < 0 ? 0 : $for;
        $special = $for ? $special : 0;
    }
    if( $in_text ) {
        $in_text = 0;
        $in_tab = 0;
        return
    } 
    elsif( $in_verbatim ) {
    }
    elsif ( $in_heading ) {
	    $in_heading = 0; 
	    $ypos += $LF*(1-$zlf); 
	    $zlf = 1;
	}
	$bl = 1;
}

sub ZLF {
	my ($str) = @_;
	if (($lineleng <= $indent - 2) and ($str =~ /\007|\d+/)) { 
    	$zlf = 0 
	} 
    else { $zlf = 1 } 
}

sub HSP {
    my $str = shift;
    my $new;
    $str =~ s/S</S<\001/g;
    foreach (split(/S</, $str)) {
        if (/\001(.*)>(.*)/) {
            my $a = $1;
            my $b = $2;
            $a =~ s/ /\240/g;
            $new .= $a.$b;
            next;
        }
        $new .= $_; 
    }		
    $new;
}
   
sub just {
    my $str = shift;
    $str .= ' ';
    my $used = 0;
    $end = ($x_size - $right_margin);
    if ($str =~ /\n/) {
	    &output($line, 0) if $line;
	    linkBB(2, 0) if ($line and @lk);
	    $line = "";
	    $k = 0;
	    $lineleng = 0;
	    $spaces = 0;
	    return;
    } 
    else {
        my $word;
        foreach $word ( split( /([ \t])/, $str ) ) {
            $tab_str= 0;
            $wordleng = 0;
            foreach ( split( //, $word ) ) {
                if( / / ) { $tab_str = 0 }
                if( /[\001-\006]/ ) { &REM($_); next; }
                if( /\t/ ) {
                    $tab_str = 1;
		            &output($line, 0) if $line;
		            linkBB(2, 0) if ($line and @lk);
		            $line = "";
		            $k = 0;
		            $used = (int($lineleng/48) + 1) * 48;
		            $xpos += $used;
		            $spaces = 0;
		            $lineleng = 0;
		            next;
                }
		        if( $in_link ) { $link_string .= $_ }
				$wordleng += $wx[ $jt[$j][0] ][ $jt[$j][1] ][ord($_)]*$fs;
            }
            if ($lineleng + $wordleng <= ($end - $xpos) or $in_verbatim or $in_tab) {
                $lineleng += $wordleng;
                $wordleng = 0;
                $line .= $word unless $word eq "\t";
                $spaces++ if $word eq " ";
            }
            else {
                $line =~ s/(.*\S)(\s*)$/$1/;
                $lineleng -= 2.5 * length($2);
                $spaces -= length $2; 
                if ($spaces < 1) { $spaces = 1 }
                $k = ($end - $xpos - $lineleng)/$spaces;
                &output($line, $k);
                linkBB(2, $k) if @lk;
                $ypos -= $LF;
                if ($ypos <= $bottom_margin) { 
                    pageFooter(); 
                    pageHeader($h_str, $title); 
                    $ypos -= 12;
                    $used = 0;
                    prt("/F$pt[$p][0]$pt[$p][1] $fs Tf\n");
                    $fonts_used{"/F$pt[$p][0]$pt[$p][1]"} = ' ';
                    @scratch_pad = ($pt[$p][0], $pt[$p][1]);
                }
                if ( $word eq " " ) { $line = ""; $lineleng = 0 }
                else { $line = $word; $lineleng = $wordleng }
                $wordleng = 0; 
                $spaces = 0;
                $used = 0;
                if ($xpos != $cLM + $indent and $tab_str) { 
                    $xpos = $cLM + $indent + 48; 
                } 
                else {
                    if ($in_heading) { $xpos = $cLM }
                    else { $xpos = $cLM + $indent }
                }
            }
        }
    }
}


sub REM {
    my $rem = shift;
    if( $rem =~ /\001/ ) { 
        if( $in_link ) { &linkBB(0, 0) } 
        $j--; 
        if ($j < 0) { $j = 0 } 
    } 
    else {
	    $jt[$j+1] = [$jt[$j][0], $jt[$j][1]]; $j++;
	    if ($rem =~ /\002/) { $jt[$j][1] = 1; }
	    if ($rem =~ /\003/) { $jt[$j][1] = 2; }
	    if ($rem =~ /\004/) { $jt[$j][0] = 1 }
	    if ($rem =~ /\005/) { $jt[$j][1] = $fontstyle{file} }
	    if ($rem =~ /\006/) { $jt[$j][1] = $fontstyle{"link"}; linkBB(1, 6) } #Link
    }
}

sub linkBB {
    my $op = shift;
    my $param = shift;
    print STDERR "linkBB($op,$param)\n" if $verbose == 2;
    if( !$op ) {
        push(@lk, $link_string, $wordleng, $spaces);
        $in_link = 0;
        $link_string = '';
	    print STDERR "\@lk = @lk\n" if $verbose == 2;
    } 
    elsif( $op == 1 ) {
        $in_link = 1;
        push(@lk, $param, ($lineleng + $xpos));
	    print STDERR "\@lk = @lk\n" if $verbose == 2;
    } 
    elsif ($op == 2) { #return if !@lk;
	    print STDERR "Sifting \@lk = @lk\n" if $verbose == 2;
	    my($linktype, $ybase,$xll,$xur,$yll,$yur);
        my $xbase = 0;
        my $str = '';
        my $len = 0;
        my $sps = 0;
        while (@lk) {
            $linktype = shift(@lk); # either 5 or 6
            $xbase = shift(@lk); $xbase = 0 if !defined $xbase;
            $ybase = $ypos;
            $str = shift(@lk); $str = '' if !defined $str;
            $len = shift(@lk); $len = 0  if !defined $len;
            $sps = shift(@lk); $sps = 0  if !defined $sps;
            if (($xbase + $len) > $end ) {
                $xbase = $cLM + $indent;
                $xbase += 48 if $tab_str;
                $sps = 0;
                $ybase -= $LF;
            }
            $xll = sprintf "%0.1f", $xbase + $sps * $param - 1;
            $xur = sprintf "%0.1f", $xll + $len + 2;
            $yll = sprintf "%0.1f", $ybase - 0.25*$LF;
            $yur = sprintf "%0.1f", $ybase + 0.63*$LF;
			if ($str =~ /(http|ftp|mailto)\s*:/) {
            	push @annot, ["[$xll $yll $xur $yur]", $str];
			}
        }
    }
}

sub pdfEscape {
    my ($line) = @_;
    $line =~ s/[\000-\024]//g;
    $line =~ s/[\\\(\)\{\}]/\\$&/g;
    $line =~ s/[\200-\377]/sprintf("\\%03o",ord($&))/ge;
    $line;
}

sub output {
    my ($line, $k) = @_;
    $k = sprintf("%0.4f", $k);
    $k = 0 if $k >= $k_max;
    $line =~ s/[\020-\024]//g;
    $line =~ s/[\\\(\)\{\}]/\\$&/g;
    $line =~ s/[\200-\377]/sprintf("\\%03o",ord($&))/ge;
    prt(sprintf "1 0 0 1 %0.1f %0.1f Tm\n", $xpos, $ypos) if $line;
    foreach ( split(/([\001-\007])/,$line) ) {
        if( /[\001-\007]/ ) {
            if( /\007/ ) { BUL() 
            }
            if( /\001/ ) { $p--; $p = 0 if( $p < 0 ) }
	        else {
		        $sc[$p+1] = $sc[$p];
                $pt[$p+1] = [$pt[$p][0], $pt[$p][1]]; $p++;
                if   ( /\002/ ) { $pt[$p][1] = 1 }                 # Bold
                elsif( /\003/ ) { $pt[$p][1] = 2 }                 # Italic
		        elsif( /\004/ ) { $pt[$p][0] = 1 }                 # Courier
		        elsif( /\005/ ) { $pt[$p][1] = $fontstyle{file} }
		        elsif( /\006/ ) {
		            $pt[$p][1] = $fontstyle{"link"};
		            $sc[$p] = 'link';
		        }
	        } 
            $fonts_used{"/F$pt[$p][0]$pt[$p][1]"} = ' ';
            prt("/F$pt[$p][0]$pt[$p][1] $fs Tf\n");
	        setColor();
	        next;
	    }
        prt("$k Tw\n");
        prt("\($_\) Tj\n");
    }
}

sub BUL {
    my $x = $xpos + 8;
    my $y = $ypos + 1;
    prt("
        ET
        q
        $xpos $y 4 4 re
        f
        Q
        BT
        1 0 0 1 $x $ypos Tm
    ");
}
        
sub setFont {
    my($set) = shift;
    my ($font, $style) = ();
    
    $fs = $setStyles{$set}[0];
    
    if    ($setStyles{$set}[1] eq 'Times'      ) { $font = 0 }
    elsif ($setStyles{$set}[1] eq 'Courier'    ) { $font = 1 }
    elsif ($setStyles{$set}[1] eq 'Helvetica'  ) { $font = 2 }
    
    else { print STDERR "$setStyles{$set}[1] ($set,$fs) is an unrecognised font\n"; exit }
    
    if    ($setStyles{$set}[2] eq 'Regular'      ) { $style = 0 }
    elsif ($setStyles{$set}[2] eq 'Bold'         ) { $style = 1 }
    elsif ($setStyles{$set}[2] eq 'Oblique'      ) { $style = 2 }
    elsif ($setStyles{$set}[2] eq 'BoldOblique'  ) { $style = 3 }
    elsif ($setStyles{$set}[2] eq 'Italic'       ) { $style = 3 }
    elsif ($setStyles{$set}[2] eq 'ItalicOblique') { $style = 3 }
    
    else { print STDERR "setStyles{$set}[2] ($set,$fs) is an unrecognised style\n"; exit }
    
    $fonts_used{"/F$font$style"} = ' ';
    prt("/F$font$style $fs Tf\n");
    @scratch_pad = ($font, $style);
    $LF = $leading * $fs;
    $uH = $LF * $heading_lift;
    $WS = $LF * $paragraph_space;
}

sub setColor {
    if( $sc[$p] ne $current_color ) {
	defined($colorstyle{$sc[$p]}) or die "INTERNAL ERROR \#05 - Unknown colorstyle\n";
    prt("$colorstyle{$sc[$p]}\n");
	$current_color = $sc[$p];
    }
}

sub stringLength {
    my ($str, $font, $style) = @_;
    my $length = 0;
    foreach (split(//, $str)) {
        $length += $wx[$font][$style][ord($_)]*$fs
    }
    $length;
}

my ($even);
sub pageFooter {
    my $date_footer = '';
    my $y0 = $bottom_bar;
    my $y1 = $y0 - 13;
    my $x0 = $left_margin;
    my $x1 = $x_size - $right_margin;
    my $x2 = 0.5 * ($x0 + $x1);
    my $p_num;

    if    ($section eq 'doc') { $p_num = $page }
    elsif ($section eq 'toc') { $p_num = $Roman[$page - $lp]; }
    elsif ($section eq 'cov') { $p_num = 'Fly leaf' }
    setFont('footer');

    if($page % 2) {
        my $buf = stringLength($p_num, @scratch_pad);
        $buf = $x1 - $buf;
        prt("
            1 0 0 1 $x0 $y1 Tm
            \($date\) Tj
            1 0 0 1 $buf $y1 Tm
            \($p_num\) Tj
        ");
    }
    else {
        my $buf = stringLength($date, @scratch_pad);
        $buf = $x1 - $buf;
        prt("
            1 0 0 1 $x0 $y1 Tm
            \($p_num\) Tj
            1 0 0 1 $buf $y1 Tm
            \($date\) Tj
        ");
    }

    prt("
        ET
        $x0 $y0 m
        $x1 $y0 l
        S
    ");
    $stream_end = $f_pos;
    $stream_length = $stream_end - $stream_start;
    prt("
        endstream
        endobj
    ");
    
    my $contents_object  = $obj;

    $o_loc[++$obj] = $f_pos;
    prt("
        $obj 0 obj
        $stream_length
        endobj
    ");
    
    $o_loc[++$obj] = $f_pos;
    my $resources_object = $obj;                      
    $buf = '';
    foreach (sort keys %fonts_used) { $buf .= "$_ $o_rec{$_} 0 R\n" }
    prt("
        $obj 0 obj
        <<
        /ProcSet [/PDF /Text]
        /ColorSpace <</DefaultRGB 1 0 R>>
        /Font
        <<
        $buf
        >>
        >>
        endobj
    ");
    
    my @annot_objects = ();
    for (0..$#annot) {
        my $next = 0;
        $o_loc[++$obj] = $f_pos;
        push(@annot_objects, $obj);
        $next = $obj+1;
        prt("
            $obj 0 obj
            <<
            /Type /Annot
            /Subtype /Link
            /Rect $annot[$_][0]
            /Border [0 0 1]
            /C [1 1 0]
            /A $next 0 R
            /H /I
            >>
            endobj
		");
    $o_loc[++$obj] = $f_pos;
        prt("
            $obj 0 obj
            <<
            /S /URI
            /URI ($annot[$_][1])
            >>
            endobj
		");
	}
	
	if (@annot) {
	    $buf = join(' 0 R ', @annot_objects, '');
    	$o_loc[++$obj] = $f_pos;
    	my $annots_object = $obj;
        prt("
            $obj 0 obj
            [ $buf ]
            endobj
		");
	    $o_loc[++$obj] = $f_pos;
	    $o_rec{$page}  = $obj;
	    prt("
	        $obj 0 obj
	        <<
	        /Type /Page
	        /Parent $o_rec{parent} 0 R
	        /Resources $resources_object 0 R
	        /Contents $contents_object 0 R
	        /Annots $annots_object 0 R
	        >>
	        endobj
	    ");
	}
	else {      
	    $o_loc[++$obj] = $f_pos;
	    $o_rec{$page}  = $obj;
	    prt("
	        $obj 0 obj
	        <<
	        /Type /Page
	        /Parent $o_rec{parent} 0 R
	        /Resources $resources_object 0 R
	        /Contents $contents_object 0 R
	        >>
	        endobj
	    ");
	}
    
    if    ($section eq 'doc') { push @Kids,      "$o_rec{$page} 0 R" }
    elsif ($section eq 'toc') { push @tocKids,   "$o_rec{$page} 0 R" }
    elsif ($section eq 'cov') { push @coverKids, "$o_rec{$page} 0 R" }

    ++$page;
}

sub pageHeader {
    my ($in_str, $out_str, $type) = @_;
    @annot = ();
    my ($l_str, $r_str);
    if ($page % 2) {
        $l_str = $in_str;
        $r_str = $out_str;
    } 
    else { 
        $l_str = $out_str;
        $r_str = $in_str;
    }
     
    my $y0 = $y_size - $top_bar;
    my $y1 = $y0 + 5;
    my $x0 = $left_margin;
    my $x1 = $x_size - $right_margin;
    my $x2 = 0.5 * ($x0 + $x1);

    undef %fonts_used;
    $o_loc[++$obj] = $f_pos;
    my $length_obj = $obj + 1;
    
    prt("
        $obj 0 obj
        <<
        /Length $length_obj 0 R
        >>
        stream
    ");
    
    $stream_start = $f_pos;
    
    if (defined $in_str) {
        prt("
            $x0 $y0 m
            $x1 $y0 l
        ")
    }
    
    prt("
        S
        BT
        0 G
        1 i 0 J 0 j 0.1 w 10 M []0 d
    ");

    setFont('header');
    if (defined $r_str and defined $l_str) {
	    my $buf = stringLength($r_str, @scratch_pad);
	    $buf = $x1 - $buf;
	    prt("
	        1 0 0 1 $x0 $y1 Tm
	        \($l_str\) Tj
	        1 0 0 1 $buf $y1 Tm
	        \($r_str\) Tj
	   ");
	}
    $yrem = $ypos = $y_size - $top_margin;
    if ($in_text) { $ypos += $LF };
}

sub prt {
    my ($str) = @_;
    $str =~ s/\n\s*/\n/g;
    $str =~ s/^\n//;
    $f_pos += length $str;
    print OUT $str;
}

sub pdf_date {
    my @date  = localtime(time);
    my $year  = $date[5] + 1900;
    my $month = sprintf "%.2d", $date[4]+1;
    my $day   = sprintf "%.2d", $date[3];
    my $hour  = sprintf "%.2d", $date[2];
    my $min   = sprintf "%.2d", $date[1];
    my $sec   = sprintf "%.2d", $date[0];
    
    my $gm = (gmtime(time))[2];
    my $local = (localtime(time))[2];
    my $diff = $local - $gm;
    if ($diff <= -12) { $diff += 24 }
    elsif ($diff > 12) { $diff -= 24 }
    my $zone = $diff;
    if ($zone =~ /-/) {$zone = sprintf "%.2d00", $zone}
    else  {$zone = sprintf "+%.2d00", $zone}

    return "D:$year$month$day$hour$min$sec$zone"
}

sub page_date {
    my @date  = localtime(time);
    my $year  = $date[5] + 1900;
    my $mon   = sprintf "%.2d", $date[4];
    my $day   = sprintf "%.2d", $date[3];
    my @month = qw(January February March April May June July August September October November December);

    return "$day $month[$mon] $year";
}

sub pdfOpen {

    my ($of) = @_;

    open(OUT, ">$of") or die "Could not open output file '$of': $!\n";
    MacPerl::SetFileInfo("CARO", "PDF ", $of) if ($^O eq "MacOS");

    print STDERR "Opening output file $of\n" if $verbose;
    
    prt("%PDF-1.2\n");
    prt("%‚„œ”\n");

    $o_loc[++$obj] = $f_pos;
    $o_rec{calRGB} = $obj;
    prt("
        $obj 0 obj
        [/CalRGB
        <<
        /WhitePoint [0.9505 1 1.089]
        /Gamma [1.8 1.8 1.8]
        /Matrix [0.4497 0.2446 0.02518 0.3613 0.672 0.1412 0.1845 0.08334 0.9227]
        >>
        ]
        endobj
    ");

    $o_loc[++$obj] = $f_pos;
    $o_rec{info} = $obj;
    prt("
        $obj 0 obj
        <<
        /CreationDate (".pdf_date().")
        /Producer (pod2pdf)
        /Title ($title)
        >>
        endobj
    ");

    $o_rec{root}   = ++$obj;
    $o_rec{parent} = ++$obj;

    $o_loc[++$obj] = $f_pos;
    $o_rec{encoding} = $obj;
    prt("
        $obj 0 obj
        <<
        /Type /Encoding
        /Differences [ 0 /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /space /exclam
        /quotedbl /numbersign /dollar /percent /ampersand
        /quoteright /parenleft /parenright /asterisk /plus /comma
        /hyphen /period /slash /zero /one /two /three /four /five
        /six /seven /eight /nine /colon /semicolon /less /equal
        /greater /question /at /A /B /C /D /E /F /G /H /I /J /K /L
        /M /N /O /P /Q /R /S /T /U /V /W /X /Y /Z /bracketleft
        /backslash /bracketright /asciicircum /underscore
        /quoteleft /a /b /c /d /e /f /g /h /i /j /k /l /m /n /o /p
        /q /r /s /t /u /v /w /x /y /z /braceleft /bar /braceright
        /asciitilde /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
        /.notdef /.notdef /.notdef /.notdef /.notdef /emdash
        /dotlessi /grave /acute /circumflex /tilde /macron /breve
        /dotaccent /dieresis /.notdef /ring /cedilla /.notdef
        /hungarumlaut /ogonek /caron /space /exclamdown /cent
        /sterling /currency /yen /brokenbar /section /dieresis
        /copyright /ordfeminine /guillemotleft /logicalnot /hyphen
        /registered /macron /degree /plusminus /twosuperior
        /threesuperior /acute /mu /paragraph /periodcentered
        /cedilla /onesuperior /ordmasculine /guillemotright
        /onequarter /onehalf /threequarters /questiondown /Agrave
        /Aacute /Acircumflex /Atilde /Adieresis /Aring /AE
        /Ccedilla /Egrave /Eacute /Ecircumflex /Edieresis /Igrave
        /Iacute /Icircumflex /Idieresis /Eth /Ntilde /Ograve
        /Oacute /Ocircumflex /Otilde /Odieresis /multiply /Oslash
        /Ugrave /Uacute /Ucircumflex /Udieresis /Yacute /Thorn
        /germandbls /agrave /aacute /acircumflex /atilde /adieresis
        /aring /ae /ccedilla /egrave /eacute /ecircumflex
        /edieresis /igrave /iacute /icircumflex /idieresis /eth
        /ntilde /ograve /oacute /ocircumflex /otilde /odieresis
        /divide /oslash /ugrave /uacute /ucircumflex /udieresis
        /yacute /thorn /ydieresis ]
        >>
        endobj
    ");

    foreach my $font (sort keys %fontdef) {
        $o_loc[++$obj] = $f_pos;
        $o_rec{$font} = $obj;
        prt("
            $obj 0 obj
            <<
            /Type /Font
            /Subtype /Type1
            /Name $font
            /Encoding $o_rec{encoding} 0 R
            /BaseFont /$fontdef{$font}
            >>
            endobj
        ");
    }
}

sub pdfTrailer {
    $o_loc[$o_rec{root}] = $f_pos;
    prt("
        $o_rec{root} 0 obj
        <<
        /Type /Catalog
        /Pages $o_rec{parent} 0 R
        /PageMode /UseOutlines
        /Outlines $o_rec{outlines} 0 R
        >>
        endobj
    ");
    my $kids = join(' ', @coverKids).' '.join(' ', @tocKids).' '.join(' ', @Kids);
    my $count = (scalar @coverKids) + (scalar @tocKids) + (scalar @Kids);
    $o_loc[$o_rec{parent}] = $f_pos;
    prt("
        $o_rec{parent} 0 obj
        <<
        /Type /Pages
        /Kids [ $kids ]
        /Count $count
        /MediaBox [0 0 $x_size $y_size]
        >>
        endobj
    ");
    
    my $xfer = $f_pos;
    prt("xref\n");
    
my $size = $obj+1;
    
    $buf = sprintf "0 %d\n", $size;
    prt($buf);
    prt("0000000000 65535 f \n");
    my $i;
    for ($i = 1; $i <= $obj; $i++) {
        $buf = sprintf "%.10d 00000 n \n", $o_loc[$i];
        prt($buf)
    }
    
    $buf = sprintf "/Size %d\n", $size;
    
    prt("
        trailer
        <<
        $buf
        /Root $o_rec{root} 0 R
        /Info $o_rec{info} 0 R
        >>
        startxref
        $xfer
        %%EOF
    ");
}

sub buildTOC {
    $ol[1]{page} = $page;
    
    pageHeader();

    setFont('ToC');
    $ypos = $y_size - 72;
    $xpos = ($x_size - stringLength('Table of Contents', @scratch_pad))/2;
    prt("
        1 0 0 1 $xpos $ypos Tm
        \(Table of Contents\) Tj
    ");
    $ypos -= $LF;
    $xpos = ($x_size - stringLength("$title", @scratch_pad))/2;
    prt("
        1 0 0 1 $xpos $ypos Tm
        \($title\) Tj
    ");

    $ypos -= 2*$LF;
    
    setFont('H3');
     for (1..$#ol) {
        next if !$ol[$_]{level};
        if ($ypos <= 70) {
            pageFooter();
            pageHeader("Table of Contents", $title);
            $ypos = $y_size - 72;
            setFont('H3');
        }
        $xpos = $left_margin + ($left_indent * ($ol[$_]{level}));
        $buf = trimString($xpos, $ol[$_]{string}, @scratch_pad);
        color_stripe($_);
        prt("
            1 0 0 1 $xpos $ypos Tm
            \($buf\) Tj
        ");
        $xpos = $x_size - $right_margin - $left_indent - stringLength($ol[$_]{page}, @scratch_pad);
        prt("
            1 0 0 1 $xpos $ypos Tm
            \($ol[$_]{page}\) Tj
        ");
        $ypos -= $LF;
    }
    pageFooter();
    unless ($page % 2) {
        pageHeader("Table of Contents", $title);
        pageFooter()
    }
}

sub trimString {
    my ($strt, $str, $font, $style) = @_;
    my $length = 0;
    my $ret = '';
    foreach (split(//, $str)) {
        $length += $wx[$font][$style][ord($_)]*$fs;
        $ret .= $_;
        if ($length + $strt > 450) {
            if ($ret =~ /(.*)\s+.*/) {
                $ret = $1.'...';
                last;
            }
        }
    }
    $ret;
} 

sub color_stripe {
    my $col;
    my $xll = $left_margin;
    my $yll = $ypos - 3;
    my $stripe = $x_size - $left_margin - $right_margin;
    if ($_[0] % 2) { $col = 1}
    else { $col = 0.95}
    prt("
        ET
        q
        $col g
        $xll $yll $stripe $LF re
        f
        Q
        BT
    ");
}

sub pdfOutline {
    my($level, $str, $page, $ypos) = @_;
    $str = pdfEscape($str);
    return unless length $str;

    if    ($level == 1) { $h2 = 0 }
    elsif ($level == 2) { $h2 = 1 }
    elsif ($level == 3 and !$h2) { $level = 2 }
        
    $ol[++$no] = { level => $level,
                  string => $str,
                    page => $page,
                    ypos => $ypos };
}

sub outlineTree {
    my $z;
    $o_rec{outlines} = ++$obj;
    $ol[0]{level} = -1;
    for (1..$no) {
        my @kids; undef @kids;
        my @gkids; undef @gkids;
        my $first = undef;
        my $last = undef;
        my $previous = undef;
        my $next = undef;
        my $count = undef;
        
        $i = $_;
        until ($ol[$i]{level} < $ol[$_]{level}) { $i-- }
        my $parent = $i;
        
        $i = $_ - 1;
        until ($ol[$i]{level} <= $ol[$_]{level}) { $i-- };
        if ($ol[$i]{level} == $ol[$_]{level}) { $previous = $i} else {$previous = undef }
 
        $i = $_ + 1;
        if ($i <= $no) {
            until (!defined $ol[$i]{level} or $ol[$i]{level} <= $ol[$_]{level}) { $i++ };
            if (defined $ol[$i]{level} and $ol[$i]{level} == $ol[$_]{level}) { $next = $i} else {$next = undef }
        }
        
        $i = $_ + 1;
        if ($i <= $no) {
            until (!defined $ol[$i]{level} or $ol[$i]{level} <= $ol[$_]{level}) {
                if ($ol[$i]{level} == $ol[$_]{level} + 1) { push(@kids,  "$i") }
                if ($ol[$i]{level} >= $ol[$_]{level} + 2) { push(@gkids, "$i") }
                $i++;
            }
            $count = (scalar @kids) + (scalar @gkids);
        }
        
        $z = $obj + $_;
        $parent += $obj if defined $parent;
        $previous += $obj if defined $previous;
        $next += $obj if defined $next;
        $first = $kids[0] + $obj if defined $kids[0];
        $last = $kids[-1] + $obj if defined $kids[-1];
        $o_loc[$z] = $f_pos;
        my $view = $ol[$_]{level} == 0 ? "/Fit" : "/FitH $ol[$_]{ypos}";
        prt("
            $z 0 obj
            <<
            /Parent $parent 0 R
            /Dest [$o_rec{$ol[$_]{page}} 0 R $view]
        ");
        prt("/Previous $previous 0 R\n") if defined $previous;
        prt("/Next $next 0 R\n") if defined $next;
        prt("/First $first 0 R\n") if defined $first;
        prt("/Last $last 0 R\n") if defined $last;
        prt("/Count $count \n") if $count;
        prt("/Title \($ol[$_]{string}\)\n");
        prt("
            >>
            endobj
        ");
    }
    $o_loc[$o_rec{outlines}] = $f_pos;
    prt("
        $o_rec{outlines} 0 obj
        <<
        /Type /Outlines
    ");
    $z = $#ol - 1;
    prt("/Count $z\n");
    $z = $obj + 1;
    prt("/First $z 0 R\n");
    $z = $obj + $#ol - 1;
    prt("
        /Last $z 0 R
        >>
        endobj
    ");
    $obj += $no;
}

sub coverPage {
    my $x;
    my $y;
    my $w;
    my $h;
    undef %fonts_used;
    
    $o_loc[++$obj] = $f_pos;
    push @coverKids, "$obj 0 R";
    $o_rec{$page} = $obj;

    my $contents_object = $obj + 1;
    my $length_obj = $obj + 2;
    my $resources_object = $obj+3;                      

    prt("
        $obj 0 obj
        <<
        /Type /Page
        /Parent $o_rec{parent} 0 R
        /Resources $resources_object 0 R
        /Contents $contents_object 0 R
        >>
        endobj
    ");
    
    $o_loc[++$obj] = $f_pos;
    
    prt("
        $obj 0 obj
        <<
        /Length $length_obj 0 R
        >>
        stream
    ");
    
    $stream_start = $f_pos;

    $x = 180;
    $y = $y_size - 216;
    my $ty = $y + 80;
    
    my $xll = 210;
    my $xlr = $x_size - $right_margin;
    
    $h = 130;
    $w = 8;
    
    prt("
        q
        1 0 0 rg
        $x $y $w $h re
        F
        Q
        0 G
        1 i 0 J 0 j 0.1 w 10 M []0 d
        $xll $y m
        $xlr $y l
        s
        BT
   ");
   
    $fonts_used{'/F21'} = ' ';
    $fonts_used{'/F22'} = ' ';
    
    prt("
        /F21 30 Tf
        1 0 0 1 210 $ty Tm
        0 -30 TD
        (POD Translation) Tj
        T* (by ) Tj
        0 0 0.8 rg
        /F22 30 Tf
        (pod2pdf) Tj
        /F21 9 Tf
        T* (ajf\@afco.demon.co.uk) Tj
    ");
    
    setFont('coverTitle');
    my $xm = ($x_size - stringLength($title, @scratch_pad))/2;
    my $ym = $y_size/2 - 50;
    
    prt("
        0 g
        1 0 0 1 $xm $ym Tm
        ($title) Tj
        ET
    ");
    
    $stream_end = $f_pos;
    $stream_length = $stream_end - $stream_start;
    
    
    prt("
        endstream
        endobj
    ");
    
    $o_loc[++$obj] = $f_pos;
    
    prt("
        $obj 0 obj
        $stream_length
        endobj
    ");
    
    $o_loc[++$obj] = $f_pos;
    $buf = '';
    foreach (sort keys %fonts_used) { $buf .= "$_ $o_rec{$_} 0 R\n" }
    
    prt("
        $obj 0 obj
        <<
        /ProcSet [/PDF /Text]
        /ColorSpace <</DefaultRGB 1 0 R>>
        /Font
        <<
        $buf
        >>
        >>
        endobj
    ");
    
    pageHeader("Title Page", $title);
    pageFooter();

    ++$page;
}

       
sub ESC {
    %HTML = (
            'lt'     => '<',          'gt'     => '>',          'amp'    => '&',         
            'quot'   => '"',          'nbsp'   => "\240",       'Aacute' => "\301",      
            'Acirc'  => "\302",       'Agrave' => "\300",       'Aring'  => "\305",      
            'Atilde' => "\303",       'Auml'   => "\304",       'Ccedil' => "\307",      
            'ETH'    => "\320",       'Eacute' => "\311",       'Ecirc'  => "\312",      
            'Egrave' => "\310",       'Euml'   => "\313",       'Iacute' => "\315",      
            'Icirc'  => "\316",       'Igrave' => "\314",       'Iuml'   => "\317",      
            'Ntilde' => "\321",       'AElig'  => "\306",       'Oacute' => "\323",      
            'Ocirc'  => "\324",       'Ograve' => "\322",       'Oslash' => "\330",      
            'Otilde' => "\325",       'Ouml'   => "\326",       'THORN'  => "\336",      
            'Uacute' => "\332",       'Ucirc'  => "\333",       'Ugrave' => "\331",      
            'Uuml'   => "\334",       'Yacute' => "\335",       'aelig'  => "\346",      
            'aacute' => "\341",       'acirc'  => "\342",       'agrave' => "\340",      
            'aring'  => "\345",       'atilde' => "\343",       'auml'   => "\344",      
            'ccedil' => "\347",       'eacute' => "\351",       'ecirc'  => "\352",      
            'egrave' => "\350",       'emdash' => "\217",       'eth'    => "\360",      
            'euml'   => "\353",       'iacute' => "\355",       'icirc'  => "\356",      
            'igrave' => "\354",       'iuml'   => "\357",       'ntilde' => "\361",      
            'oacute' => "\363",       'ocirc'  => "\364",       'ograve' => "\362",      
            'oslash' => "\370",       'otilde' => "\365",       'ouml'   => "\366",      
            'thorn'  => "\376",       'uacute' => "\372",       'ucirc'  => "\373",      
            'ugrave' => "\371",       'uuml'   => "\374",       'yacute' => "\375",      
            'yuml'   => "\377",       'reg'    => "\256",       'copy'   => "\251",
            'szlig'  => 'sz',         '39'     => "\047",       '96'     => "\140");
}


#############################################################################
# Font Metrics (font widths) - Data from Adobe Font Metrics Files
#############################################################################

sub afm {
    $wx[0][0] =
	[			#Times-Roman ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.250,  0.333,  0.408,  0.500,  0.500,  0.833,  0.778,  0.333,  
	 0.333,  0.333,  0.500,  0.564,  0.250,  0.333,  0.250,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  
	 0.500,  0.500,  0.278,  0.278,  0.564,  0.564,  0.564,  0.444,  
	 0.921,  0.722,  0.667,  0.667,  0.722,  0.611,  0.556,  0.722,  
	 0.722,  0.333,  0.389,  0.722,  0.611,  0.889,  0.722,  0.722,  
	 0.556,  0.722,  0.667,  0.556,  0.611,  0.722,  0.722,  0.944,  
	 0.722,  0.722,  0.611,  0.333,  0.278,  0.333,  0.469,  0.500,  
	 0.333,  0.444,  0.500,  0.444,  0.500,  0.444,  0.333,  0.500,  
	 0.500,  0.278,  0.278,  0.500,  0.278,  0.778,  0.500,  0.500,  
	 0.500,  0.500,  0.333,  0.389,  0.278,  0.500,  0.500,  0.722,  
	 0.500,  0.500,  0.444,  0.480,  0.200,  0.480,  0.541,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.250,  0.333,  0.500,  0.500,  0.500,  0.500,  0.200,  0.500,  
	 0.333,  0.760,  0.276,  0.500,  0.564,  0.333,  0.760,  0.333,  
	 0.400,  0.564,  0.300,  0.300,  0.333,  0.500,  0.453,  0.250,  
	 0.333,  0.300,  0.310,  0.500,  0.750,  0.750,  0.750,  0.444,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.889,  0.667,  
	 0.611,  0.611,  0.611,  0.611,  0.333,  0.333,  0.333,  0.333,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.564,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.556,  0.500,  
	 0.444,  0.444,  0.444,  0.444,  0.444,  0.444,  0.667,  0.444,  
	 0.444,  0.444,  0.444,  0.444,  0.278,  0.278,  0.278,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.564,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  
	 ];

    $wx[0][1] =
	[			#Times-Bold ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.250,  0.333,  0.555,  0.500,  0.500,  1.000,  0.833,  0.333,  
	 0.333,  0.333,  0.500,  0.570,  0.250,  0.333,  0.250,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  
	 0.500,  0.500,  0.333,  0.333,  0.570,  0.570,  0.570,  0.500,  
	 0.930,  0.722,  0.667,  0.722,  0.722,  0.667,  0.611,  0.778,  
	 0.778,  0.389,  0.500,  0.778,  0.667,  0.944,  0.722,  0.778,  
	 0.611,  0.778,  0.722,  0.556,  0.667,  0.722,  0.722,  1.000,  
	 0.722,  0.722,  0.667,  0.333,  0.278,  0.333,  0.581,  0.500,  
	 0.333,  0.500,  0.556,  0.444,  0.556,  0.444,  0.333,  0.500,  
	 0.556,  0.278,  0.333,  0.556,  0.278,  0.833,  0.556,  0.500,  
	 0.556,  0.556,  0.444,  0.389,  0.333,  0.556,  0.500,  0.722,  
	 0.500,  0.500,  0.444,  0.394,  0.220,  0.394,  0.520,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.250,  0.333,  0.500,  0.500,  0.500,  0.500,  0.220,  0.500,  
	 0.333,  0.747,  0.300,  0.500,  0.570,  0.333,  0.747,  0.333,  
	 0.400,  0.570,  0.300,  0.300,  0.333,  0.556,  0.540,  0.250,  
	 0.333,  0.300,  0.330,  0.500,  0.750,  0.750,  0.750,  0.500,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  1.000,  0.722,  
	 0.667,  0.667,  0.667,  0.667,  0.389,  0.389,  0.389,  0.389,  
	 0.722,  0.722,  0.778,  0.778,  0.778,  0.778,  0.778,  0.570,  
	 0.778,  0.722,  0.722,  0.722,  0.722,  0.722,  0.611,  0.556,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.722,  0.444,  
	 0.444,  0.444,  0.444,  0.444,  0.278,  0.278,  0.278,  0.278,  
	 0.500,  0.556,  0.500,  0.500,  0.500,  0.500,  0.500,  0.570,  
	 0.500,  0.556,  0.556,  0.556,  0.556,  0.500,  0.556,  0.500,  
	 ];

    $wx[0][2] =
	[			#Times-Italic ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.250,  0.333,  0.420,  0.500,  0.500,  0.833,  0.778,  0.333,  
	 0.333,  0.333,  0.500,  0.675,  0.250,  0.333,  0.250,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  
	 0.500,  0.500,  0.333,  0.333,  0.675,  0.675,  0.675,  0.500,  
	 0.920,  0.611,  0.611,  0.667,  0.722,  0.611,  0.611,  0.722,  
	 0.722,  0.333,  0.444,  0.667,  0.556,  0.833,  0.667,  0.722,  
	 0.611,  0.722,  0.611,  0.500,  0.556,  0.722,  0.611,  0.833,  
	 0.611,  0.556,  0.556,  0.389,  0.278,  0.389,  0.422,  0.500,  
	 0.333,  0.500,  0.500,  0.444,  0.500,  0.444,  0.278,  0.500,  
	 0.500,  0.278,  0.278,  0.444,  0.278,  0.722,  0.500,  0.500,  
	 0.500,  0.500,  0.389,  0.389,  0.278,  0.500,  0.444,  0.667,  
	 0.444,  0.444,  0.389,  0.400,  0.275,  0.400,  0.541,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.889,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.250,  0.389,  0.500,  0.500,  0.500,  0.500,  0.275,  0.500,  
	 0.333,  0.760,  0.276,  0.500,  0.675,  0.333,  0.760,  0.333,  
	 0.400,  0.675,  0.300,  0.300,  0.333,  0.500,  0.523,  0.250,  
	 0.333,  0.300,  0.310,  0.500,  0.750,  0.750,  0.750,  0.500,  
	 0.611,  0.611,  0.611,  0.611,  0.611,  0.611,  0.889,  0.667,  
	 0.611,  0.611,  0.611,  0.611,  0.333,  0.333,  0.333,  0.333,  
	 0.722,  0.667,  0.722,  0.722,  0.722,  0.722,  0.722,  0.675,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.556,  0.611,  0.500,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.667,  0.444,  
	 0.444,  0.444,  0.444,  0.444,  0.278,  0.278,  0.278,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.675,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.444,  0.500,  0.444,  
	 ];

    $wx[0][3] =
	[			#Times-BoldItalic ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.250,  0.389,  0.555,  0.500,  0.500,  0.833,  0.778,  0.333,  
	 0.333,  0.333,  0.500,  0.570,  0.250,  0.333,  0.250,  0.278,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  
	 0.500,  0.500,  0.333,  0.333,  0.570,  0.570,  0.570,  0.500,  
	 0.832,  0.667,  0.667,  0.667,  0.722,  0.667,  0.667,  0.722,  
	 0.778,  0.389,  0.500,  0.667,  0.611,  0.889,  0.722,  0.722,  
	 0.611,  0.722,  0.667,  0.556,  0.611,  0.722,  0.667,  0.889,  
	 0.667,  0.611,  0.611,  0.333,  0.278,  0.333,  0.570,  0.500,  
	 0.333,  0.500,  0.500,  0.444,  0.500,  0.444,  0.333,  0.500,  
	 0.556,  0.278,  0.278,  0.500,  0.278,  0.778,  0.556,  0.500,  
	 0.500,  0.500,  0.389,  0.389,  0.278,  0.556,  0.444,  0.667,  
	 0.500,  0.444,  0.389,  0.348,  0.220,  0.348,  0.570,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.250,  0.389,  0.500,  0.500,  0.500,  0.500,  0.220,  0.500,  
	 0.333,  0.747,  0.266,  0.500,  0.606,  0.333,  0.747,  0.333,  
	 0.400,  0.570,  0.300,  0.300,  0.333,  0.576,  0.500,  0.250,  
	 0.333,  0.300,  0.300,  0.500,  0.750,  0.750,  0.750,  0.500,  
	 0.667,  0.667,  0.667,  0.667,  0.667,  0.667,  0.944,  0.667,  
	 0.667,  0.667,  0.667,  0.667,  0.389,  0.389,  0.389,  0.389,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  0.570,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.611,  0.611,  0.500,  
	 0.500,  0.500,  0.500,  0.500,  0.500,  0.500,  0.722,  0.444,  
	 0.444,  0.444,  0.444,  0.444,  0.278,  0.278,  0.278,  0.278,  
	 0.500,  0.556,  0.500,  0.500,  0.500,  0.500,  0.500,  0.570,  
	 0.500,  0.556,  0.556,  0.556,  0.556,  0.444,  0.500,  0.444,  
	 ];      

    $wx[2][0] =
	[			#Helvetica ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.278,  0.278,  0.355,  0.556,  0.556,  0.889,  0.667,  0.222,  
	 0.333,  0.333,  0.389,  0.584,  0.278,  0.584,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  
	 0.556,  0.556,  0.278,  0.278,  0.584,  0.584,  0.584,  0.556,  
	 1.015,  0.667,  0.667,  0.722,  0.722,  0.667,  0.611,  0.778,  
	 0.722,  0.278,  0.500,  0.667,  0.556,  0.833,  0.722,  0.778,  
	 0.667,  0.778,  0.722,  0.667,  0.611,  0.722,  0.667,  0.944,  
	 0.667,  0.667,  0.611,  0.278,  0.278,  0.278,  0.469,  0.556,  
	 0.222,  0.556,  0.556,  0.500,  0.556,  0.556,  0.278,  0.556,  
	 0.556,  0.222,  0.222,  0.500,  0.222,  0.833,  0.556,  0.556,  
	 0.556,  0.556,  0.333,  0.500,  0.278,  0.556,  0.500,  0.722,  
	 0.500,  0.500,  0.500,  0.334,  0.260,  0.334,  0.584,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.278,  0.333,  0.556,  0.556,  0.556,  0.556,  0.260,  0.556,  
	 0.333,  0.737,  0.370,  0.556,  0.584,  0.333,  0.737,  0.333,  
	 0.400,  0.584,  0.333,  0.333,  0.333,  0.556,  0.537,  0.278,  
	 0.333,  0.333,  0.365,  0.556,  0.834,  0.834,  0.834,  0.611,  
	 0.667,  0.667,  0.667,  0.667,  0.667,  0.667,  1.000,  0.722,  
	 0.667,  0.667,  0.667,  0.667,  0.278,  0.278,  0.278,  0.278,  
	 0.722,  0.722,  0.778,  0.778,  0.778,  0.778,  0.778,  0.584,  
	 0.778,  0.722,  0.722,  0.722,  0.722,  0.667,  0.667,  0.611,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.889,  0.500,  
	 0.556,  0.556,  0.556,  0.556,  0.278,  0.278,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.584,  
	 0.611,  0.556,  0.556,  0.556,  0.556,  0.500,  0.556,  0.500,  
	 ];

    $wx[2][1] =
	[			#Helvetica-Bold ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.278,  0.333,  0.474,  0.556,  0.556,  0.889,  0.722,  0.278,  
	 0.333,  0.333,  0.389,  0.584,  0.278,  0.584,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  
	 0.556,  0.556,  0.333,  0.333,  0.584,  0.584,  0.584,  0.611,  
	 0.975,  0.722,  0.722,  0.722,  0.722,  0.667,  0.611,  0.778,  
	 0.722,  0.278,  0.556,  0.722,  0.611,  0.833,  0.722,  0.778,  
	 0.667,  0.778,  0.722,  0.667,  0.611,  0.722,  0.667,  0.944,  
	 0.667,  0.667,  0.611,  0.333,  0.278,  0.333,  0.584,  0.556,  
	 0.278,  0.556,  0.611,  0.556,  0.611,  0.556,  0.333,  0.611,  
	 0.611,  0.278,  0.278,  0.556,  0.278,  0.889,  0.611,  0.611,  
	 0.611,  0.611,  0.389,  0.556,  0.333,  0.611,  0.556,  0.778,  
	 0.556,  0.556,  0.500,  0.389,  0.280,  0.389,  0.584,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.278,  0.333,  0.556,  0.556,  0.556,  0.556,  0.280,  0.556,  
	 0.333,  0.737,  0.370,  0.556,  0.584,  0.333,  0.737,  0.333,  
	 0.400,  0.584,  0.333,  0.333,  0.333,  0.611,  0.556,  0.278,  
	 0.333,  0.333,  0.365,  0.556,  0.834,  0.834,  0.834,  0.611,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  1.000,  0.722,  
	 0.667,  0.667,  0.667,  0.667,  0.278,  0.278,  0.278,  0.278,  
	 0.722,  0.722,  0.778,  0.778,  0.778,  0.778,  0.778,  0.584,  
	 0.778,  0.722,  0.722,  0.722,  0.722,  0.667,  0.667,  0.611,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.889,  0.556,  
	 0.556,  0.556,  0.556,  0.556,  0.278,  0.278,  0.278,  0.278,  
	 0.611,  0.611,  0.611,  0.611,  0.611,  0.611,  0.611,  0.584,  
	 0.611,  0.611,  0.611,  0.611,  0.611,  0.556,  0.611,  0.556,  
	 ];

    $wx[2][2] =
	[			#Helvetica-Oblique ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.278,  0.278,  0.355,  0.556,  0.556,  0.889,  0.667,  0.222,  
	 0.333,  0.333,  0.389,  0.584,  0.278,  0.584,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  
	 0.556,  0.556,  0.278,  0.278,  0.584,  0.584,  0.584,  0.556,  
	 1.015,  0.667,  0.667,  0.722,  0.722,  0.667,  0.611,  0.778,  
	 0.722,  0.278,  0.500,  0.667,  0.556,  0.833,  0.722,  0.778,  
	 0.667,  0.778,  0.722,  0.667,  0.611,  0.722,  0.667,  0.944,  
	 0.667,  0.667,  0.611,  0.278,  0.278,  0.278,  0.469,  0.556,  
	 0.222,  0.556,  0.556,  0.500,  0.556,  0.556,  0.278,  0.556,  
	 0.556,  0.222,  0.222,  0.500,  0.222,  0.833,  0.556,  0.556,  
	 0.556,  0.556,  0.333,  0.500,  0.278,  0.556,  0.500,  0.722,  
	 0.500,  0.500,  0.500,  0.334,  0.260,  0.334,  0.584,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.278,  0.333,  0.556,  0.556,  0.556,  0.556,  0.260,  0.556,  
	 0.333,  0.737,  0.370,  0.556,  0.584,  0.333,  0.737,  0.333,  
	 0.400,  0.584,  0.333,  0.333,  0.333,  0.556,  0.537,  0.278,  
	 0.333,  0.333,  0.365,  0.556,  0.834,  0.834,  0.834,  0.611,  
	 0.667,  0.667,  0.667,  0.667,  0.667,  0.667,  1.000,  0.722,  
	 0.667,  0.667,  0.667,  0.667,  0.278,  0.278,  0.278,  0.278,  
	 0.722,  0.722,  0.778,  0.778,  0.778,  0.778,  0.778,  0.584,  
	 0.778,  0.722,  0.722,  0.722,  0.722,  0.667,  0.667,  0.611,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.889,  0.500,  
	 0.556,  0.556,  0.556,  0.556,  0.278,  0.278,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.584,  
	 0.611,  0.556,  0.556,  0.556,  0.556,  0.500,  0.556,  0.500,  
	 ];

    $wx[2][3] =
	[			#Helvetica-BoldOblique ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.278,  0.333,  0.474,  0.556,  0.556,  0.889,  0.722,  0.278,  
	 0.333,  0.333,  0.389,  0.584,  0.278,  0.584,  0.278,  0.278,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  
	 0.556,  0.556,  0.333,  0.333,  0.584,  0.584,  0.584,  0.611,  
	 0.975,  0.722,  0.722,  0.722,  0.722,  0.667,  0.611,  0.778,  
	 0.722,  0.278,  0.556,  0.722,  0.611,  0.833,  0.722,  0.778,  
	 0.667,  0.778,  0.722,  0.667,  0.611,  0.722,  0.667,  0.944,  
	 0.667,  0.667,  0.611,  0.333,  0.278,  0.333,  0.584,  0.556,  
	 0.278,  0.556,  0.611,  0.556,  0.611,  0.556,  0.333,  0.611,  
	 0.611,  0.278,  0.278,  0.556,  0.278,  0.889,  0.611,  0.611,  
	 0.611,  0.611,  0.389,  0.556,  0.333,  0.611,  0.556,  0.778,  
	 0.556,  0.556,  0.500,  0.389,  0.280,  0.389,  0.584,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  1.000,  
	 0.278,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  0.333,  
	 0.333,  0.000,  0.333,  0.333,  0.000,  0.333,  0.333,  0.333,  
	 0.278,  0.333,  0.556,  0.556,  0.556,  0.556,  0.280,  0.556,  
	 0.333,  0.737,  0.370,  0.556,  0.584,  0.333,  0.737,  0.333,  
	 0.400,  0.584,  0.333,  0.333,  0.333,  0.611,  0.556,  0.278,  
	 0.333,  0.333,  0.365,  0.556,  0.834,  0.834,  0.834,  0.611,  
	 0.722,  0.722,  0.722,  0.722,  0.722,  0.722,  1.000,  0.722,  
	 0.667,  0.667,  0.667,  0.667,  0.278,  0.278,  0.278,  0.278,  
	 0.722,  0.722,  0.778,  0.778,  0.778,  0.778,  0.778,  0.584,  
	 0.778,  0.722,  0.722,  0.722,  0.722,  0.667,  0.667,  0.611,  
	 0.556,  0.556,  0.556,  0.556,  0.556,  0.556,  0.889,  0.556,  
	 0.556,  0.556,  0.556,  0.556,  0.278,  0.278,  0.278,  0.278,  
	 0.611,  0.611,  0.611,  0.611,  0.611,  0.611,  0.611,  0.584,  
	 0.611,  0.611,  0.611,  0.611,  0.611,  0.556,  0.611,  0.556,  
	 ];

    $wx[1][0] =
	[			#Courier ISOLatin1
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  
	 0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.000,  0.600,  0.600,  0.000,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  0.600,  
	 ];

    $wx[1][1] = $wx[1][2] = $wx[1][3] = $wx[1][0];
}

#NB Width of Times 'hyphen' (ASCII 45) altered to 0.333 which MacOS returns

1;

__END__

=head1 NAME

Pdf.pm -- A POD to PDF translator

=head1 SYNOPSIS

All systems:

	pod2pdf([options])
 
Also from the shell prompt in conjunction with the script "pod2pdf" (see "scripts/pod2pdf"):

	$ pod2pdf [options] <file>

E<nbsp>

=head1 DESCRIPTION

C<pod2pdf> translates single C<POD> (Perl Plain Old Documentation) files and translates them to C<PDF> (Adobe Portable Document Format) files. Future extensions to this program may permit translation of multiple C<POD> files into a single book. At this stage the emphasis is on simplicity and ease of use. The output C<PDF> file takes the name of the input file with the suffix C<.pdf>.

C<PDF Outlines> are created at three levels corresponding to C<=head1>, C<=head2> and C<=item>. The C<outline> headings are reproduced as a C<Table of Contents> page. Long C<=item> strings are curtailed to a length which will fit reasonably in the space available on the page. When the C<PDF> document is viewed on screen, the C<outlines> (sometimes known as C<Bookmarks>) provide links to the appropriate page. When the document is printed the C<ToC> provides the same facility.

Links of the form L<xyz.pm> and links to named destinations are not implemented since it is rarely possible to resolve the link except in the limited instance of links to named destinations in the document itself. Links to C<URL> addresses (including I<http>, I<ftp> and I<mailto>) are active however and call the resident default browser. How that responds to the call will depend to some extent on the type of browser and the environment in which it finds itself.

The C<POD> specification C<perlpod.pod> allows blocks of text to be enclosed by C<=begin> and C<=end> markers. The block-type my be indicated by a string after C<=begin> (for example C<=begin html> would indicate an C<HTML> block) of which I<roff, man, latex, tex and html> are recognised entities. Specification C<perlpod.pod> goes on to say that I<"A formatter that can utilize that format will use the section, otherwise it will be completely ignored."> This seems to defeat the object of the documentation since quite different output might be expected according to which translator was used. It is doubtful if that would necessarily be the author's intention.

This translator, C<Pdf.pm>, in all cases reproduces the section enclosed by a C<=begin/=end> pair (or any paragraph following C<=for> which is similarly defined in C<perlpod.pod>) but in a special color so as to give a visual warning to the reader that special meaning might attach to the block of text. 

The primary objective is to produce a translation of a C<POD> file of good typographical quality which can be printed on any printer (particularly low-cost non-PostScript ink-jet printers) in any environment. In this connection it must be recognised that some authors use C<POD> mark-up more intelligently and to better effect than others. Not infrequently mistakes in formatting (frequently the absence of a blank line to end a block) result in files which do not translate properly on some or all translators. C<PDF> files provide the very useful ability to quickly screen the translation for visual checking before the file is despatched to the printer.

=head1 OPTIONS

In the interests of simplicity and ease of use the number of options has been kept to a minimum. However an option to set paper size remains an unavoidable necessity untill such time as the world can agree on one standard. Only B<A4> and B<USLetter> are preprogrammed, other custom sizes will require an edit to the C<Pdf.pm> code.

Options are implemented using C<Getopt::Long> using the syntax C<--[key]=> as indicated below. The order in which options are entered is immaterial.

=item B<Paper size>

The default paper size is A4 (which may be re-editied to a custom size):

	my $x_size = 595;  # default page width  (pixels)
	my $y_size = 842;  # default page height (pixels)
	
The option:
	
	--paper=usletter
		
sets the North American standard size:

	my $x_size = 612;  # US letter page width  (pixels)
	my $y_size = 792;  # US letter page height (pixels)
	
The program will accept any (reasonable) paper size.

=item B<Error reporting>

Limited error reporting to STDERR may be turned on by setting C<$verbose>:

	--verbose=1     # progress reports
	--verbose=2     # more extensive progress reports about links
	
=item B<Input filename>

The input file name may be entered in various ways on most sytems. It may be included as an B<option>, or as a string argument to C<pod2pdf>, or as an item in C<@ARGV> or finally, as a command line entry on systems which support command lines. As an C<option> the syntax is:

	--podname=filename
	
=item B<Duplex printing>

The output is always "duplex" in the sense that the pages are "handed" with the page number (for example) at the bottom right (on odd pages) and the bottom left (on even pages). However not everyone possesses a duplex printer capable of automatically printing on both sides of the paper, but fortunately most if not all printers are capable of printing all the odd sides in one pass and all the even pages (on the reverse side of the paper) in a second pass, which achieves the same result. Even if that is either not possible or not worth the effort, and the whole document is printed single sided, the handing of the pages is no great drawback. There is really no compelling need for the complication of a switch to select simplex or duplex mode.

=item B<Document name>

Since the program is restricted to processing single C<POD> files the input file name can be used as the output file name distinguished simply by adding the extension C<.pdf> to that name. If a file of that name already exists it will be overwritten without warning.

=head1 EXAMPLES

=over 4

=item Example 1 (all platforms)

 use Pod::Pdf;
 push @ARGV, qw(--paper usletter --verbose 1);
 # alternatively "push @ARGV, qw(-paper usletter -verbose 1)"
 # but NB "push @ARGV, '--verbose 2'" will NOT work
 push @ARGV, 'podfilename';
 pod2pdf(@ARGV);

=item Example 2 (all platforms)

 use Pod::Pdf;
 pod2pdf(
     '--paper=usletter',
     'podfilename'
 );

=item Example 3 (all platforms)

 use Pod::Pdf;
 pod2pdf(
     '--paper=usletter',
     '--verbose=2',
     '--podfile=podfilename'
 );

=item Example 4 (MacOS droplet)

 use Pod::Pdf;
 unshift @ARGV, '--paper=usletter';
 pod2pdf(@ARGV);

=head1 AUTHOR

Alan J. Fry

=item e-mail L<mailto:ajf@afco.demon.co.uk>

=item WWW L<http://www.afco.demon.co.uk>

=head1 HISTORY

=item Version 1.0 released 04 April 2000

=item Version 1.1 released 18 April 2000 

This version supports active URI links and features improved formatting.

=over 4

For many helpful suggestions sincere thanks (in alphabetical order) to:

Stas Bekman <sbekman@stason.org>

Rob Carraretto <carraretto@telus.net>

M. Christian Hanson <chanson@banta-im.com>

Marcus Harnisch <harnisch@mikrom.de>

Johannes la Poutré <jlpoutre@corp.nl.home.com>

Henrik Tougaard <ht000@foa.dk>

=back

=item Version 1.2 released 26 May 2000

This version has essentially the same functionality as version 1.1 but is reshaped into modular format. In reshaping the module grateful thanks are due to Axel Rose L<http://www.roeslein.de/axel/> whose suggestion to place the opening statements of the program into the subroutine C<pod2pdf> has been adopted together with his proposals for exporting the function name. This arrangement brings C<Pdf.pm> more into line with the structure of other POD translators. His assistance in testing the module on a variety of platforms (MacOS, Linux and Windows) has been invaluable as has his advice on the structure of the interface and many fine details too numerous to mention individually.

=head1 VERSION

=item v1.2 Friday, 26 May 2000

=head1 COPYRIGHT 

=item © Alan J. Fry April 2000

=item This program is distributed under the terms of the Artistic Licence

=cut
