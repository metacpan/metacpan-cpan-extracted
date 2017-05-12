package PlotCalendar::Month;

#
#	Version 1.0 -  3/99 - Alan Jackson : ajackson at icct.net
#			 Copyright 1999 may be used and distributed under the
#			Gnu Copyleft.

#	Version 1.1 - 6/99 - major code cleanup and documentation

#  To do
#   flag to drop empty rows (yes/no)
#	 actually add in the Tk stuff!
#	should add something to support Javascript (I suppose)
#


use strict;
use vars qw( $VERSION );

use Carp;
use PlotCalendar::DateTools qw(Add_Delta_Days Day_of_Week Day_of_Year Days_in_Month Decode_Day_of_Week Day_of_Week_to_Text Month_to_Text);
use PlotCalendar::Day;

#	Note : Day_of_Week returns 1=Mon, 7=Sun

$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ m#(\d+)\.(\d+)#;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

		#  Values to apply to all cells

	 $self->{MONTH} = ''; # Month (1-12)
	 $self->{YEAR} = ''; # Year (4 digits, like 1999)
	 $self->{SIZE} = {}; # hash of dimensions, height and width
	 $self->{CLIPTEXT} = 0; # Clip text if too long? default = no.
	 $self->{FONT} = {}; # hash of font sizes, day, main, opt
	 $self->{STYLES} = {}; # hash of font styles, day, main, opt (n,b,i,u)
	 $self->{EXPAND} = 0; # Is height allowed to expand? default = no.
	 $self->{FIRST} = 'Sun'; # What day of the week is in the first column?
	 $self->{ARTWORK} = ''; # What is the path to the artwork directory?
	 $self->{CELLWIDTH} = ''; # total width / 7
	 $self->{TABLEBG} = '#66FFFF'; # Table Background color
	 $self->{'FONT_TABLE'}={}; # convert between points and html fonts 
	 $self->{MONTHREF}=''; # html reference for month/year

		# Values that are arrays to be applied to each cell

	 $self->{FGCOLOR} = []; # array of foreground colors 
	 $self->{BGCOLOR} = []; # array of background colors 
	 $self->{DAYNAME} = []; # What is the day called (like, "Christmas")
	 $self->{TEXT} = []; # array of pointers to arrays of lines of text
	 $self->{TEXTCOL} = []; # array of pointers to arrays of text colors
	 $self->{TEXTSIZE} = []; # array of pointers to arrays of text sizes
	 $self->{TEXTSTYLE} = []; # array of pointers to arrays of text styles
	 $self->{TEXTREF} = []; # array of pointers to arrays of text html refs
	 $self->{NAMEREF} = []; # array of html refs for the dayname

	 $self->{COMMENTS} = []; # array of pointers to arrays for comment days
	                         # These are "days" that will be put into the
							 # blank areas at the beginning and end of the
							 # calendar.
							 # [\@preference,\@text,\@color,\@style,\@size]
							 # preference = 'before' or 'after'. If the 
							 # preferred position is not available, use
							 # the other. If neither is available, expand
							 # the month by adding a new row on the bottom.

	 $self->{COMMFLAG} = 0;  # Are there comments? 0=no, 1=yes
	 $self->{HTMLREF} = []; # array of html references to be applied to cells

	 $self->{MONTH} = shift;
	 $self->{YEAR} = shift;

	 &initialize($self);

    bless $self, $class;

	 return $self;

}

# ****************************************************************
sub gettext {
    my $self = shift;

	 return \@{$self->{DATES}};
}

# ****************************************************************
sub gethtml {
    my $self = shift;

	 my $string='';

	 my $begday = $self->{FIRST}; # What day of the week is the first day of the month?

	#	initialize table

	$string = "<TABLE BORDER=1 BGCOLOR=$self->{TABLEBG} WIDTH=$self->{SIZE}{width} >\n";
	if ($self->{CELLWIDTH} < 40) { 
		$string = "<TABLE BORDER=0 BGCOLOR=$self->{TABLEBG} WIDTH=$self->{SIZE}{width} >\n";
	}

	#	Month-year header
		#	If there is no artwork directory, use bold headings, 
		#   1 size larger than digit

	my $month = Month_to_Text($self->{MONTH});
	my $year = $self->{YEAR};
	my ($r1,$r2) = ('','');
	if ($self->{MONTHREF} ne '') { 
		$r1 = $self->{MONTHREF};
		$r2 = '</A>';
	}
	my $labels = "$r1<B><FONT SIZE=$self->{FONT_TABLE}{($self->{FONT}{day}+2)}>$month $year</FONT></B>$r2";

	if ($self->{ARTWORK} ne '') {
		my $mon = $self->{ARTWORK} . "/" . $month . ".gif";
		my $yr = '';
		foreach my $i (split('',$year)) {
			$yr .= '<IMG SRC="' . $self->{ARTWORK} . "/" . $i . '.gif">' . "\n";
		}
		$labels = $r1 . '<IMG SRC="' . $mon . '">&nbsp;&nbsp;' . $yr . $r2;
	}

	$string .= "<TR><TD COLSPAN=7 WIDTH=$self->{SIZE}{width} >";
	$string .= "<CENTER>$labels</CENTER>\n";
	$string .= "</TD></TR>\n";

	#	Weekday names

	$string .= "<TR>\n";
	my $frstdow = Decode_Day_of_Week($begday);
	for (my $i=0;$i<7;$i++) {
		my $dow = ($frstdow + $i)%7;
		$dow = $dow ? $dow : 7; # if = 0, set = to 7
		$string .= "<TD ALIGN=center VALIGN=bottom WIDTH=$self->{CELLWIDTH} NOSAVE NOWRAP>";
		my $textdow = Day_of_Week_to_Text($dow);
		if ($self->{CELLWIDTH} < 80) { $textdow = substr($textdow,0,3);}
		if ($self->{CELLWIDTH} < 40) { 
			$textdow = substr($textdow,0,1);
			$string .= "<B>" . $textdow . "</B>";
		}
		else {
			$string .= "<H3>" . $textdow . "</H3>";
		}
		$string .= "</TD>\n";
	}
	$string .= "</TR>\n";

	#	If there are comments, we'll need to deal with them

	 my $comments = 0;
	 my (@prefs, @comments, @comcol, @comstyle, @comsize);
	 if ($self->{COMMFLAG}) {
	 	@prefs = @{$self->{COMMENTS}[0]};
	 	@comments = @{$self->{COMMENTS}[1]};
	 	@comcol = @{$self->{COMMENTS}[2]};
	 	@comstyle = @{$self->{COMMENTS}[3]};
	 	@comsize = @{$self->{COMMENTS}[4]};
		$comments = @prefs;
	 }

	#	add in all the days

	my $numdays = Days_in_Month($year, $self->{MONTH}); # num days in month
	my $dow = Day_of_Week($year, $self->{MONTH},1); # day of week of first
	my $curday = 0; # current day of month
   $dow = 0 if $dow == 7;
   $frstdow = 0 if $frstdow == 7;

	my $valid=0;

	for (my $row=0;$row<6;$row++) {
		 $string .= "<TR>\n";
		 last if $row >= 4 && $curday >= $numdays; # don't add an empty row
		 for (my $col=0;$col<7;$col++) {
		 	if ( ($col+$frstdow)%7 == $dow){ $valid = 1 ;} # flag for starting
			$curday++ if $valid;
			if ($curday > $numdays) { $valid = 0 ;} # flag for stopping
		 	# Is this and empty cell?
			if ( $valid ) { # ---- actually build the day cell here ----
				my $day = PlotCalendar::Day->new($curday);
				$day -> size($self->{CELLWIDTH},$self->{CELLWIDTH});
				$day -> font($self->{FONT}{day},$self->{FONT}{main},$self->{FONT}{opt},);
				$day -> style($self->{STYLES}{day},$self->{STYLES}{main},$self->{STYLES}{opt},);
				$day -> cliptext($self->{CLIPTEXT});
				$day -> dayname($self->{DAYNAME}[$curday]);
				$day -> nameref($self->{NAMEREF}[$curday]);
				$day -> color($self->{FGCOLOR}[$curday],$self->{BGCOLOR}[$curday],'WHITE',);;
				$day -> text(@{$self->{TEXT}[$curday]});
				$day -> textcolor(@{$self->{TEXTCOL}[$curday]});
				$day -> textsize(@{$self->{TEXTSIZE}[$curday]});
				$day -> textstyle(@{$self->{TEXTSTYLE}[$curday]});
				$day -> textref(@{$self->{TEXTREF}[$curday]});
				if ($self->{HTMLREF}[$curday]) {
					$day -> htmlref($self->{HTMLREF}[$curday]);
				}
				$string .= $day -> gethtml; # ---- add in cell
			}
			else { 
				if ($comments && $curday == 0 && grep(/before/,@prefs)) {
						# I am in the before zone and can use it
						my $k;
						for ($k=0;$k<@prefs;$k++) {
							last if $prefs[$k] eq 'before' ;
						}
						$string .= &makecomm($self,$comments[$k],$comcol[$k],$comstyle[$k],$comsize[$k]);
						splice(@prefs,$k,1);
						splice(@comments,$k,1);
						splice(@comcol,$k,1);
						splice(@comstyle,$k,1);
						splice(@comsize,$k,1);
						$comments--;
				}
				elsif ($comments && $curday > 0 ) {
						# I am in the after zone and can use it
						$string .= &makecomm($self,$comments[0],$comcol[0],$comstyle[0],$comsize[0]);
						shift @prefs;
						shift @comments;
						shift @comcol;
						shift @comstyle;
						shift @comsize;
						$comments--;
				}
				else {
					$string .= "<TD WIDTH=$self->{CELLWIDTH} BGCOLOR=$self->{TABLEBG}>&nbsp;  </TD>\n";
				}
			}
		 }
		  $string .= "</TR>\n";
	 }
	 #	If I have leftover comments, I have to create an extra row to display them
	 if ($comments) {
		 $string .= "<TR>\n";
		 for (my $col=0;$col<7;$col++) {
			if ($comments) {
				# I am in the after zone and can use it
				$string .= &makecomm($self,$comments[0],$comcol[0],$comstyle[0],$comsize[0]);
				shift @prefs;
				shift @comments;
				shift @comcol;
				shift @comstyle;
				shift @comsize;
				$comments--;
			}
			else {
				$string .= "<TD WIDTH=$self->{CELLWIDTH} BGCOLOR=$self->{TABLEBG}>&nbsp;  </TD>\n";
			}
		 	
		 }
		 $string .= "</TR>\n";
	 }

	 # finish up
	 $string .= "</TABLE>\n";

	 return $string;
}

sub makecomm {
	my $output = '';
	my $self = shift;
	my $comm = shift;
	my $color = shift;
	my $style = shift;
	my $size = shift;
	my $day = PlotCalendar::Day->new(0);
	$day -> size($self->{CELLWIDTH},$self->{CELLWIDTH});
	$day -> font($self->{FONT}{day},$self->{FONT}{main},$self->{FONT}{opt},);
	$day -> style($self->{STYLES}{day},$self->{STYLES}{main},$self->{STYLES}{opt},);
	$day -> color('BLACK',$self->{TABLEBG},'WHITE',);;

	$day -> text(@{$comm});
	$day -> textcolor(($color)x@{$comm});
	$day -> textsize(($size)x@{$comm});
	$day -> textstyle(($style)x@{$comm});
	$output = $day -> gethtml; # ---- add in cell

	return $output;
}

# ****************************************************************
sub gettk {
    my $self = shift;

	 return 0;
}

# ****************************************************************
sub getascii {
    my $self = shift;

	 my $string='';

	 my $begday = $self->{FIRST}; # What day of the week is the first day of the month?

	my $month = Month_to_Text($self->{MONTH});
	my $year = $self->{YEAR};
	my $labels = "$month $year";
	$string .= "$labels\n";

	#	add in all the days

	my $numdays = Days_in_Month($year, $self->{MONTH}); # num days in month

	for (my $dom=1;$dom<=$numdays;$dom++) {
		my $dayofweek = Day_of_Week_to_Text(Day_of_Week($year,$self->{MONTH},$dom));
		$string .= "\n--- $self->{MONTH}/$dom $dayofweek ---\n";
		my $day = PlotCalendar::Day->new($dom);
		$day -> dayname($self->{DAYNAME}[$dom]);
		$day -> text(@{$self->{TEXT}[$dom]});
		$string .= $day -> getascii; # ------- add a day
	}

	 # [\@preference,\@text,\@color,\@style,\@size]
	 #	print out comments, if there are any

	 if ($self->{COMMFLAG}) {
	 	my @text = @{$self->{COMMENTS}[1]};
		$string .= join("\n",@text) . "\n";
	 }


	 return $string;
}

# ****************************************************************
sub dayname {
	my $self = shift;
	if (@_) {
	   @{$self->{DAYNAME}} = @_;
	}
	else { return @{$self->{DAYNAME}};}
}

# ****************************************************************
sub htmlref {
	my $self = shift;
	if (@_) {
	   @{$self->{HTMLREF}} = @_;
	}
	else { return @{$self->{HTMLREF}};}
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
sub textref {
	my $self = shift;
	if (@_) {
	   @{$self->{TEXTREF}} = @_;
	}
	else { return @{$self->{TEXTREF}};}
}

# ****************************************************************
sub nameref {
	my $self = shift;
	if (@_) {
	   @{$self->{NAMEREF}} = @_;
	}
	else { return @{$self->{NAMEREF}};}
}

# ****************************************************************
sub comments {
	my $self = shift;
	if (@_) {
	   @{$self->{COMMENTS}} = @_;
	   $self->{COMMFLAG}=1;
	}
	else { return @{$self->{COMMENTS}};}
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
sub bgcolor {
	my $self = shift;
	if (@_) {
		if ($#_ > 0) { # I have an array
			@{$self->{BGCOLOR}} = @_;
		}
		else { # I have a single value
			my $color = shift;
			for (my $i=1;$i<=31;$i++) {
				$self->{BGCOLOR}[$i] = $color;
			}
		}
	}
	else { return @{$self->{BGCOLOR}};}
}

# ****************************************************************
sub fgcolor {
	my $self = shift;
	if (@_) {
		if ($#_ > 0) { # I have an array
			@{$self->{FGCOLOR}} = @_;
		}
		else { # I have a single value
			my $color = shift;
			for (my $i=1;$i<=31;$i++) {
				$self->{FGCOLOR}[$i] = $color;
			}
		}
	}
	else { return @{$self->{FGCOLOR}};}
}

# ****************************************************************
sub artwork {
	my $self = shift;
	if (@_) {
		$self->{ARTWORK} = shift;
	}
	else { return $self->{ARTWORK};}
}

# ****************************************************************
sub firstday {
	my $self = shift;
	my @tst = qw( Sun Mon Tue Wed Thu Fri Sat );
	my %tst;
	for (@tst) { $tst{$_} = 1; }
	if (@_) {
		my $day = shift;
		if ( defined $tst{$day} ) {
			 $self->{FIRST} = $day;
		}
		else { die "Bad day value in call to firstday in Month.pm - $day\n";}
	}
	else { return $self->{FIRST};}
}

# ****************************************************************
sub monthref {
	my $self = shift;
	if (@_) {
	   $self->{MONTHREF} = shift;
	}
	else { return $self->{MONTHREF}}
}

# ****************************************************************
sub cliptext {
	my $self = shift;
	if (@_) {
	   $self->{CLIPTEXT} = shift;
	}
	else { return $self->{CLIPTEXT}}
}

# ****************************************************************
sub size {
	my $self = shift;
	if (@_) {
	   $self->{SIZE}{height} = shift;
	   $self->{SIZE}{width} = shift;
		$self->{CELLWIDTH} = int($self->{SIZE}{width}/7);
	}
	else { return ($self->{SIZE}{height},$self->{SIZE}{width});}
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
sub styles {
	my $self = shift;
	if (@_) {
	   $self->{STYLES}{day} = shift;
	   $self->{STYLES}{main} = shift;
	   $self->{STYLES}{opt} = shift;
	}
	else { return ($self->{STYLES}{day},$self->{STYLES}{main},$self->{STYLES}{opt},);}
}

# ****************************************************************
sub initialize {
    my $self = shift;
	 
	 #	default values

	 $self->{SIZE}{height} = 700;
	 $self->{SIZE}{width} = 700;
	 $self->{FONT}{day} = '14';
	 $self->{FONT}{main} = '10';
	 $self->{FONT}{opt} = '8';
	 $self->{STYLES}{day} = 'b';
	 $self->{STYLES}{main} = 'bi';
	 $self->{STYLES}{opt} = 'n';
	 for (my $i=1;$i<=31;$i++) {
		  $self->{FGCOLOR}[$i] = 'BLACK'; 
		  $self->{BGCOLOR}[$i] = '#33cc00'; # green
		  $self->{DAYNAME}[$i] = ''; 
	 }

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

	PlotCalendar::Month - Plot an ASCII or HTML calendar

=head1 SYNOPSIS

Creates a Month object for plotting as ASCII, HTML, or in a Perl/Tk
Canvas. Calls Day.pm for the individual days within the calendar.

=head1 DESCRIPTION

Measurements in pixels because - well, because. It seemed simpler when
I made the decision. And it works for both Tk and HTML.

The month is laid out like this :


           Month_name                          Year

    ---------------------------------------------------------------
    | Sun    | Mon    | Tue    | Wed   | Thu    | Fri    | Sat    |
    ---------------------------------------------------------------
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        |
    |        |        |        |       |        |        |        |
    |--------|--------|--------|-------|--------|--------|--------|
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        |
    |        |        |        |       |        |        |        |
    |--------|--------|--------|-------|--------|--------|--------|
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        |
    |        |        |        |       |        |        |        |
    |--------|--------|--------|-------|--------|--------|--------|
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        |
    |        |        |        |       |        |        |        |
    |--------|--------|--------|-------|--------|--------|--------|
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        |
    |        |        |        |       |        |        |        |
    |--------|--------|--------|-------|--------|--------|--------|
    |        |        |        |       |        |        |        |
    | day    | day    |        |       |        |        |        | optional
    |        |        |        |       |        |        |        | row
    |--------|--------|--------|-------|--------|--------|--------|

    Globals : height, width, fgcol,
    bgcolmain, 


    References expect to be given the entire thing, that is
    <A HREF="http://yaddayaddayadda/">
    or
    <A HREF="mailto:george_tirebiter@noway.nohow">

    The software will terminate it with a </A> at the right spot.

    

=head1 EXAMPLE

	require PlotCalendar::Month;

	my $month = PlotCalendar::Month->new(01,1999); # Jan 1999

	# global values, to be applied to all cells

	------------------------- size of whole calendar
	$month -> size(700,700); # width, height in pixels
	------------------------- font sizes for digit, name of day, and text
	$month -> font('14','10','8');
	------------------------- clip text if it wants to wrap?
	$month -> cliptext('yes');
	------------------------- This can be any day you want
	$month -> firstday('Sun'); # First column is Sunday
	------------------------- If this is not set, regular text will be used.
	------------------------- If it is set, then in that directory should be
	------------------------- gif files named 0.gif, 1.gif ... January.gif, ...
	$month -> artwork('/home/ajackson/public_html/cgi-bin/Calendar/Calendar_art3/'); 

	#	arrays of values, if not an array, apply to all cells, if an array
	#  apply to each cell, indexed by day-of-month

	The colors are the standard values used in html
	Textstyle encoding is b=bold, i=italic, u=underline, n=normal
	Fontsize = 6-14, roughly point sizes

	my @text;
	my @daynames;
	my @nameref;
	my @bgcolor;
	my @colors = ('WHITE','#33cc00','#FF99FF','#FF7070','#FFB0B0',);
	my (@textcol,@textsize,@textstyle,@textref);
	my @style = ('i','u','b',);
	my @url;

	----------- build some random color and text fields as a demo

	for (my $i=1;$i<=31;$i++) {
		$daynames[$i] = "Day number $i";
		$nameref[$i] = "<A HREF=\"http://www.$i.ca\">";
		$bgcolor[$i] = $colors[$i%5];
		@{$text[$i]} = ("Text 1 for $i","Second $i text","$i bit of text",);
		@{$textref[$i]} = ("<A HREF=\"http://www.$i.com/\">","Second $i text","<A HREF=\"http://www.$i.net/\">",);
		@{$textcol[$i]} = ($colors[($i+1)%5],$colors[($i+2)%5],$colors[($i+3)%5]);
		@{$textsize[$i]} = ("8","10","8",);
		@{$textstyle[$i]} = @style;
		@style = reverse(@style);
		$url[$i] = '<A href="http://some.org/name_number_' . $i . '">';
	}


	------------------------- Set global values
	$month -> fgcolor('BLACK',); #  Global foreground color
	$month -> bgcolor(@bgcolor); # Background color per day
	$month -> styles('b','bi','ui',); # Global text styles

	#	Comments

	my @prefs = ('before','after','after');
	my @comments = (['Comment one'],["Comment two","and so on"],['Comment three']);
	my @comcol = qw(b g b);
	my @comstyle = qw(n b bi);
	my @comsize = qw(8 10 14);

	------------------------- Comments get stuck into an otherwise empty cell
	$month->comments(\@prefs,\@comments,\@comcol,\@comstyle,\@comsize);

	------------------------- Wrap a hotlink around the whole day, for each day
	$month -> htmlref(@url);

	------------------------- set the names for every day
	$month -> dayname(@daynames);
	------------------------- wrap the name in a hotlink
	$month -> nameref(@nameref);

	------------------------- set the text and it's properties for each day
	$month -> text(@text);
	$month -> textcolor(@textcol);
	$month -> textsize(@textsize);
	$month -> textstyle(@textstyle);
	$month -> textref(@textref);

	#	global HTML only options

	----------------- allow days to expand vertically to accomodate text
	
	$month -> htmlexpand('yes');

	#	grab an ascii calendar and print it
	
	my $text = $month -> getascii;

	print $text;

	------------------- get the html calendar

	my $html = $month -> gethtml;

	print "<HTML><BODY>\n";
	print $html;

=head1 SEE ALSO

	Also look at Day.pm

=head1 DEPENDENCIES

	PlotCalendar::DateTools

This is a pure perl replacement for Date::Calc. I needed it because
Date::Calc contains C code which my web hosting service did not have
available for CGI-BIN stuff. 


=head1 AUTHOR

	Alan Jackson
	March 1999
	ajackson@icct.net

=cut
