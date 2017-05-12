package PlotCalendar::Day;

#
#	Version 1.0 -  3/99 - Alan Jackson : ajackson at icct.net
#			 Copyright 1999 may be used and distributed under the
#			Gnu Copyleft.

#	Version 1.1 - 6/99 Major code cleanup, and testing really big and
#	really tiny images. Added documentation.

#  To do
#   Add popup for clipped text (or maybe put it in message bar)
#	Add more intelligence for clip text
#	Add all the Tk stuff 8-)
#
#

use strict;
use vars qw( $VERSION );

use Carp;

#	Note : Day_of_Week returns 1=Mon, 7=Sun

$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ m#(\d+)\.(\d+)#;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};


	 $self->{SIZE} = {}; # hash of dimensions, height and width
	 $self->{COLOR} = {}; # hash of global colors, 
	                      # foreground, background-main, background-optional
	                      # (fg, bgmain)
	 $self->{FONT} = {}; # hash of global font sizes, day, main, opt
	 $self->{STYLE} = {}; # hash of global text styles, day, main, opt (n,b,i,u)
	 $self->{EXPAND} = 0; # Is height allowed to expand? default = no.
	 $self->{CLIPTEXT} = 0; # Clip text if too long? default = no.
	 $self->{DIGIT} = ''; # What day *is* it, anyway?
	 $self->{DAYNAME} = ''; # What is the day called (like, "Christmas")
	 $self->{NAMEREF} = ''; # HTML reference for dayname
	 $self->{HTMLREF} = ''; # HTML reference for whole cell
	 $self->{TEXT} = []; # array of lines of text
	 $self->{TEXTCOL} = []; # array of colors for text (optional)
	 $self->{TEXTSIZE} = []; # array of sizes for text (optional)
	 $self->{TEXTSTYLE} = []; # array of styles for text (optional) (n,b,i,u)
	                          # (n)ormal, (b)old, (i)talic, (u)nderline
	 $self->{TEXTREF} = []; # array of html references to text

	 $self->{"FONT_TABLE"}={}; # Table of points to html font sizes

	 $self->{DIGIT} = shift;

	 &initialize($self);

    bless $self, $class;

	 return $self;

}

# ****************************************************************
sub getascii {
    my $self = shift;

	 my $string='';

	 # name
	 $string .= "$self->{DAYNAME}\n";

	 # text
	 for (my $i=0;$i<=$#{$self->{TEXT}};$i++) {
	 	my $text = $self->{TEXT}[$i];
		$string .= "$text\n";
	 }

	 return $string;
}

# ****************************************************************
sub gethtml {
    my $self = shift;

	 my $string='';

	# initialize cell

	 my ($htmlref,$htmlref2)= ('','');
	 if ($self->{HTMLREF}) {$htmlref = $self->{HTMLREF};$htmlref2='</A>';}

	 $string  = "<TD BGCOLOR=$self->{COLOR}{bgmain} ALIGN=LEFT VALIGN=TOP ";
	 $string .= "HEIGHT=$self->{SIZE}{height} WIDTH=$self->{SIZE}{width}>$htmlref\n";

	#	digit
	my ($style1,$style2)=('','');
	if ($self->{DIGIT} != 0) {
	  ($style1,$style2) = htmlstyles($self->{STYLE}{day});
	  $string .= "$style1<FONT SIZE=$self->{'FONT_TABLE'}{$self->{FONT}{day}} ";
	  $string .= "COLOR=$self->{COLOR}{fg} > $self->{DIGIT} </FONT>$style2\n";
	}
	 # name
	 if ($self->{FONT}{main} > 0) {
		my ($r1,$r2) = ('','');
		 if ($self->{NAMEREF}) {($r1,$r2) = ($self->{NAMEREF},"</A>");}
		 ($style1,$style2) = htmlstyles($self->{STYLE}{main});
		 $string .= "$style1<FONT SIZE=$self->{'FONT_TABLE'}{$self->{FONT}{main}} ";
		 $string .= "COLOR=$self->{COLOR}{fg} >$r1 $self->{DAYNAME} $r2</FONT>$style2\n";
	 }

	 # text
	 if ($self->{FONT}{opt} > 0) {
		 ($style1,$style2) = htmlstyles($self->{STYLE}{opt});
		 my $textmax=100;
		 if ($self->{CLIPTEXT}) { # pixels/char ~= 6 + fontsize(0,1,2,3)
			$textmax = int($self->{SIZE}{width}/(6+$self->{'FONT_TABLE'}{$self->{FONT}{opt}})+.5);
		 }
		 $string .= "<FONT SIZE=$self->{'FONT_TABLE'}{$self->{FONT}{opt}} ";
		 $string .= "COLOR=$self->{COLOR}{fg} >\n ";
		 $string .= "$style1\n ";
		 for (my $i=0;$i<=$#{$self->{TEXT}};$i++) {
			my $text = $self->{TEXT}[$i];
			if ($self->{CLIPTEXT}) {$text = substr($text,0,$textmax);}

			my ($c,$z,$s1,$s2,$r1,$r2,)=('','','','','','',);
			if (defined $self->{TEXTCOL}[$i]) {$c= "COLOR=" . $self->{TEXTCOL}[$i];}
			if (defined $self->{TEXTSIZE}[$i]) {$z= "SIZE=" . $self->{FONT_TABLE}{$self->{TEXTSIZE}[$i]};}
			if (defined $self->{TEXTSTYLE}[$i]) {($s1,$s2)= htmlstyles($self->{TEXTSTYLE}[$i]);}
			if ($self->{TEXTREF}[$i]) {($r1,$r2) = ($self->{TEXTREF}[$i],"</A>");}

			if ($s1) { $string .= "<BR>$r1 $style2<FONT $c $z> $s1 $text $s2</FONT>$style1 $r2\n";}
			else { $string .= "<BR>$r1 <FONT $c $z> $text </FONT>$r2\n";}
		 }
		 $string .= "$style2</FONT>";
	 }

	 # finish up
	 $string .= "$htmlref2</TD>\n";

	 return $string;
}

# ****************************************************************
sub gettk {
    my $self = shift;

	 return $self->{DAYS};
}

# ****************************************************************
sub htmlstyles {
    my $codes = shift;

	my ($s1,$s2) = ('','');

	 foreach my $code (split('',$codes)) {
	 	 if ($code eq 'n') {$s1 .= ' '; $s2 .= ' ';}
	 	 if ($code eq 'b') {$s1 .= '<B>'; $s2 = '</B>' . $s2;}
	 	 if ($code eq 'i') {$s1 .= '<I>'; $s2 = '</I>' . $s2;}
	 	 if ($code eq 'u') {$s1 .= '<U>'; $s2 = '</U>' . $s2;}
	 }

	 return ($s1,$s2);
}

# ****************************************************************
sub dayname {
	my $self = shift;
	if (@_) {
	   $self->{DAYNAME} = shift;
	}
	else { return $self->{DAYNAME};}
}

# ****************************************************************
sub htmlref {
	my $self = shift;
	if (@_) {
	   $self->{HTMLREF} = shift;
	}
	else { return $self->{HTMLREF};}
}

# ****************************************************************
sub text {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXT}} = @_;
	}
	else { return @{$self->{TEXT}};}
}

# ****************************************************************
sub htmlexpand {
	my $self = shift;
	my @ans = qw( no yes );
	if (@_) {
	   $self->{EXPAND} = 0;
	   if ( $_[0] eq 'yes' ) {$self->{EXPAND} = 1;}
	}
	else { return $ans[$self->{EXPAND}];}
}

# ****************************************************************
sub cliptext {
	my $self = shift;
	my @ans = qw( no yes );
	if (@_) {
	   $self->{CLIPTEXT} = 0;
	   if ( $_[0] eq 'yes' ) {$self->{CLIPTEXT} = 1;}
	}
	else { return $ans[$self->{CLIPTEXT}];}
}

# ****************************************************************
sub size {
	my $self = shift;
	if (@_) {
	   $self->{SIZE}{height} = shift;
	   $self->{SIZE}{width} = shift;
	}
	else { return ($self->{SIZE}{height},$self->{SIZE}{width});}
}

# ****************************************************************
sub color {
	my $self = shift;
	if (@_) {
	   $self->{COLOR}{fg} = shift;
	   $self->{COLOR}{bgmain} = shift;
	}
	else { return ($self->{COLOR}{fg},$self->{COLOR}{bgmain},);}
}

# ****************************************************************
sub font {
	my $self = shift;
	if (@_) {
	   $self->{FONT}{day} = shift;
	   $self->{FONT}{main} = shift;
	   $self->{FONT}{opt} = shift;
	}
	else { return ($self->{FONT}{day},$self->{FONT}{main},$self->{FONT}{opt},);}
}

# ****************************************************************
sub style {
	my $self = shift;
	if (@_) {
	   $self->{STYLE}{day} = shift;
	   $self->{STYLE}{main} = shift;
	   $self->{STYLE}{opt} = shift;
	}
	else { return ($self->{STYLE}{day},$self->{STYLE}{main},$self->{STYLE}{opt},);}
}

# ****************************************************************
sub textcolor {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXTCOL}} = @_;
	}
	else { return @{$self->{TEXTCOL}};}
}

# ****************************************************************
sub textsize {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXTSIZE}} = @_;
	}
	else { return @{$self->{TEXTSIZE}};}
}

# ****************************************************************
sub textstyle {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXTSTYLE}} = @_;
	}
	else { return @{$self->{TEXTSTYLE}};}
}

# ****************************************************************
sub nameref {
	my $self = shift;
	if (@_) {
	   $self->{NAMEREF} = shift;
	}
	else { return $self->{NAMEREF};}
}

# ****************************************************************
sub textref {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXTREF}} = @_;
	}
	else { return @{$self->{TEXTREF}};}
}

# ****************************************************************
sub initialize {
    my $self = shift;
	 
	 @{$self->{COLORS}} = qw(v w g v w g);

	 #	default values

	 $self->{SIZE}{height} = 100;
	 $self->{SIZE}{width} = 100;
	 $self->{COLOR}{fg} = 'BLACK'; 
	 $self->{COLOR}{bgmain} = '#33cc00'; # green
	 $self->{FONT}{day} = '14';
	 $self->{FONT}{main} = '10';
	 $self->{FONT}{opt} = '8';
	 $self->{STYLE}{day} = 'b';
	 $self->{STYLE}{main} = 'b';
	 $self->{STYLE}{opt} = 'n';

	 #	utility values

	 %{$self->{'FONT_TABLE'}}=( 
	                          "3" => "-2",
	                          "4" => "-2",
	                          "5" => "-1",
	                          "6" => "-1",
							  "7" => "+0",
							  "8" => "+0",
							  "9" => "+1",
							  "10" => "+1",
							  "11" => "+2",
							  "12" => "+2",
							  "13" => "+3",
							  "14" => "+3",
							  "15" => "+4",
							  "16" => "+4",
	 	                     ); 
	 
}

1; 
__END__

=head1 NAME

PlotCalendar::Day - Generate ascii or html for a single day in a calendar

=head1 SYNOPSIS

Creates a Day object for plotting as ASCII, HTML, or in a Perl/Tk
Canvas. Intended to be gathered together by Month.pm to create
a traditional calendar.

=head1 DESCRIPTION

Measurements in pixels because - well, because. It seemed simpler when
I made the decision. And it works for both Tk and HTML.

The day is laid out like this :

    ------------------------------------------
    |         |        |                     |
    | digit   | digit  | Main day name       |
    |         |        |                     |
    |         |        |                     |
    |         |        |                     |
    |---------|--------|                     | <- bgcolmain
    |                                        |
    |                                        |
    |                                        |
    | Optional text                          |
    |      .                                 |
    |                                        |
    | Optional Text                          |
    |      .                                 |
    |      .                                 |
    |      .                                 | 
    |      .                                 |
    | Optional text                          |
    |      .                                 |
    |      .                                 |
    |      .                                 |
    |      .                                 |
    ------------------------------------------

    Globals : height, width, dayfont, mainfont, optfont, fgcol,
    bgcolmain, digit

    Optionals : dayname, optext[...]

    Font sizes in HTML translate as (rounding up) :
        6->-1
        8->+0
        10->+1
        12->+2
        14->+3

Various quantities can be set globally, or over-ridden for specific cases.

This is really meant to be called by month.pm to construct a calendar,
but calling it with a *really big size* is a way to "zoom in" on a
given day

=head1 EXAMPLE

	require PlotCalendar::Day;

	my $digit=10 ; # do it for the tenth
	my $day = PlotCalendar::Day->new($digit);

	#	 These are values with default settings, so these are optional

    ------------ size of whole thing in pixels, X,Y
	$day -> size(100,100);
    ------------ Global foreground and background colors
	$day -> color('BLACK','#33cc00',);
	$day -> color('WHITE','RED',);
    ------------ Font sizes for digits, dayname, and optional text
	$day -> font('14','10','8');
    ------------ styles for digits, dayname, and optional text
    ------------ b=bold, i=italic, u=underline, n=normal
	$day -> style('bi','nbu','i');
    ------------ Clip text to avoid wrapping? (yes/no)
	$day -> cliptext('yes');

	#	HTML only options
	
    ------------ is it allowed to expand vertically if there is too much text?
	$day -> htmlexpand('yes');

	#	These values are defaulted to blank

    ------------ day name
	$day -> dayname('Groundhog Day');
    ------------ if set, name is a hotlink
	$day -> nameref('<A href="http://ooga.booga.com/">');
    ------------ if set, text string is a hotlink. Note that an array is getting
    ------------ passed. Text is passed as an array also. Each line of text is
    ------------ an array element. THis example hotlinks only the first 2 lines.
	$day -> textref('<A href="http://booga.booga.com/">','<A href="mailto:>');
    ------------ Text strings, passed as elemnts of an array
	$day -> text('text string 1','text string 2','abcdefghijklmno 0 1 2 3 4 5 6 7 8 9 0',);
    ------------ override default text colors and set each string individually
	$day -> textcolor('BLUE','RED','GREEN',);
    ------------ override default text sizes and set each string individually
	$day -> textsize('8','10','8',);
    ------------ override default text styles and set each string individually
	$day -> textstyle('b','u','bi',);

    ------------ wrap a reference around the entire cell
	$day->htmlref('<A href="http://this_is_a_url/">');

    ------------ unload what I set
	my @size = $day->size;
	my @color = $day->color;
	my @font = $day->font;
	my @text = $day->text;
	my $dayname = $day->dayname;

	#	So, what do we have now?

    ------------ Create an ascii text cell
	#my $text = $day -> gettext;

    ------------ Create and return html for a cell in a table
	my $html = $day -> gethtml;

    ------------ Create and return Tk code (not implemented yet)
	#my $tk = $day -> gettk;

	print "<HTML><BODY>\n";
	print "<H1>Normal Day</H1>\n";
	print "<TABLE BORDER=1><TR>\n";
	print $html;
	print "</TR></TABLE>\n";


=head1 AUTHOR

	Alan Jackson
	March 1999
	ajackson@icct.net

=cut
