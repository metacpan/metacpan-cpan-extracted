package PostScript::Poster;

use strict;
use vars qw/$VERSION %mediatable/;
use IO::File;
use POSIX;

$VERSION = '0.02';

=head1 NAME

Hints - Perl extension for posterizing PostScript

=head1 SYNOPSIS

	use PostScript::Poster;

	my $poster = new PostScript::Poster;

	$poster->posterize(-infile => 'a.ps', -outfile => 'b.ps',
		-media => 'a4');

=head1 DESCRIPTION

Posterizing PostScript like external program poster. Based on source of
Jos T.J. van Eijdnhoven <J.T.J.v.Eijndhoven@ele.tue.nl>
poster from The Netherlands from 1999.

=head1 THE POSTSCRIPT::POSTER CLASS

=head2 new

Constructor create instance of PostScript::Poster class.

	my $poster = new PostScript::Poster;

=cut

sub new {
	my $class = shift;
	my $obj = bless { }, $class;
	my %par = @_;
	for (keys %par) { $obj->{$_} = $par{$_}; }
	return $obj;
}

=head2 posterize

Posterize -infile to -outfile according to arguments.

Parameters:
	-infile			input file name
	-outfile		output file name
	-insize			input image size
	-cutmargin		horizontal and vertical cutmargin
	-whitemargin		horizontal and vertical additional white margin
	-media			media paper size
	-poster			output poster size
	-scale			linear scale factor for poster

You must use at least one of -scale, -poster or -media parameters and you can't
use -scale and -poster simultaneously. -insize, -media and -poster parameters
are box parameter like 'A4', '3x3letter', '10x25cm', '200x200+10,10p' etc.
Margins are classic box parameters or percentual number like '200%' etc.

Default values are -media => A4, -cutmargin => 5% and -insize readed from input
file.

	$poster->posterize(-infile => 'a.ps', -outfile => 'b.ps',
		-media => 'a4');

=cut

sub posterize {
	my $obj = shift;
	my %args = @_;

	$args{-media} = 'A4' unless exists $args{-media};
	$args{-cutmargin} = '5%' unless exists $args{-cutmargin};
	$args{-whitemargin} = 0 unless exists $args{-whitemargin};

	if ($args{-scale} and $args{-poster}) {
		die q!You can't specify both -scale and -poster parameters!;
	}
	my @mediasize = $obj->box_convert($args{-media});

	if ($mediasize[3] < $mediasize[2]) {
		die 'Media should always be specified in portrait format';
	}
	if ($mediasize[2]-$mediasize[0] <= 10.0
			or $mediasize[3]-$mediasize[1] <= 10.0) {
		die 'Media size is ridiculous';
	}

	$obj->{mediasize} = \@mediasize;

	$args{-poster} = $args{-media} unless $args{-scale} or $args{-poster};
	my @cutmargin = $obj->margin_convert($args{-cutmargin});
	my @whitemargin = $obj->margin_convert($args{-whitemargin});

	my $ihandle = new IO::File $args{-infile},'r';
	return unless defined $ihandle;

	my $ohandle = new IO::File "> $args{-outfile}";
	unless (defined $ohandle) { undef $ohandle; return; }

	my $myname = $0;
	$myname =~ s/^.*\///;
	print $ohandle "%!PS-Adobe-3.0\n%%Creator: $myname => PostScript::Poster $VERSION\n";

	my $dsc_cont = my $atend = my $inbody = my $level = 0;
	my @psbb = ();
	while (<$ihandle>) {
		unless (/^%/) {
			$dsc_cont = 0;  ++$inbody unless $inbody;
			last if $atend;  next;
		}
		if (/^%%\+/ and $dsc_cont) { print $ohandle $_;  next; }
		$dsc_cont = 0;
		if (/^%%EndComments/i) { $inbody = 1;  last if $atend; }
		elsif (/^%%Begin(Document|Data)/i) { ++$level; }
		elsif (/^%%End(Document|Data)/i) { --$level; }
		elsif (/^%%Trailer/i and not $level) { $inbody = 2; }
		elsif (/^%%BoundingBox:/i and $inbody != 1 and not $level) {
			my $readed = $_;  $readed =~ s/^%%BoundingBox:\s*//i;
			if ($readed =~ /^(atend)/i) { ++$atend; } 
				else { @psbb = split /\s+/,$readed; }
		} elsif (/^%%Document/i and $inbody != 1 and not $level) {
			my $readed = $_;  $readed =~ s/^%%Document\S+\s*//i;
			if ($readed =~ /^(atend)/i) { ++$atend; } 
				else { print $ohandle $_; ++$dsc_cont; }
		}
	}

	$args{-insize} = 'A4' unless @psbb or $args{-insize};
	my @imagebb = ();
	if ($args{-insize}) {
		@imagebb = $obj->box_convert($args{-insize});
	} else {
		@imagebb = @psbb[0..3];
	}

	if ($imagebb[2]-$imagebb[0] <= 0 or $imagebb[3]-$imagebb[2] <= 0) {
		die "Input image should have positive size!\n";
	}

	my $drawablex = $mediasize[2] - 2*$cutmargin[0];
	my $drawabley = $mediasize[3] - 2*$cutmargin[1];

	my ($nx0,$ny0,$nx1,$ny1,$sizex,$sizey);

	if ($args{-scale}) {
		my $scale = $args{-scale};
		if ($scale < 0.01 or $scale > 1e6) {
			die "Illegal scale value $scale!";
		}
		$sizex = ($imagebb[2]-$imagebb[0])*$scale+2*$whitemargin[0];
		$sizey = ($imagebb[3]-$imagebb[1])*$scale+2*$whitemargin[1];

		# without rotation
		$nx0 = POSIX::ceil($sizex / $drawablex);
		$ny0 = POSIX::ceil($sizey / $drawabley);
		
		# with rotation
		$nx1 = POSIX::ceil($sizex / $drawabley);
		$ny1 = POSIX::ceil($sizey / $drawablex);

	} else {
		my @tmp = $obj->box_convert($args{-poster});
		if ($tmp[0] != 0 or $tmp[1] != 0) {
			print STDERR "Poster lower-left coordinates are assumed 0!\n";
			$tmp[0] = $tmp[1] = 0;
		}	
		if ($tmp[2]-$tmp[0] <= 0 or $tmp[3]-$tmp[1] <= 0) {
			die "Poster should have positive size!\n";
		}
		if ($tmp[3]-$tmp[1] < $tmp[2]-$tmp[0]) {
			# hmm ... landscape ... change to portrait for now
			@tmp = ($tmp[1],$tmp[0],$tmp[3],$tmp[2]);
		}
		if ($imagebb[3]-$imagebb[1] < $imagebb[2]-$imagebb[0]) {
			# image ... landscape ... change to landscape
			@tmp = ($tmp[1],$tmp[0],$tmp[3],$tmp[2]);
		}

		# without rotation
		$nx0 = POSIX::ceil (0.95 * $tmp[2] / $mediasize[2]);
		$ny0 = POSIX::ceil (0.95 * $tmp[3] / $mediasize[3]);
		
		# with rotation
		$nx1 = POSIX::ceil (0.95 * $tmp[2] / $mediasize[3]);
		$ny1 = POSIX::ceil (0.95 * $tmp[3] / $mediasize[2]);
	}

	# decide for rotation to get the minimum page count
	my $rotate = ($nx0*$ny0 > $nx1*$ny1);

	my $ncols = ($rotate ? $nx1 : $nx0);
	my $nrows = ($rotate ? $ny1 : $ny0);

	if ($nrows * $ncols > 400) {
		die "However $nrows"."x$ncols pages seems ridiculous to me!\n";
	}

	my $mediax = $ncols * ($rotate ? $drawabley : $drawablex);
	my $mediay = $nrows * ($rotate ? $drawablex : $drawabley);

	my $scale = '';
	unless ($args{-scale}) {
		# no scaling number
		my $scalex = ($mediax-2*$whitemargin[0])/($imagebb[2]-$imagebb[0]);
		my $scaley = ($mediay-2*$whitemargin[1])/($imagebb[3]-$imagebb[1]);
		$scale = ($scalex < $scaley) ? $scalex : $scaley;

		$sizex = $scale * ($imagebb[2] - $imagebb[0]);
		$sizey = $scale * ($imagebb[3] - $imagebb[1]);
	} else {
		$scale = $args{-scale};
	}

	my $p0 = ($mediax - $sizex)/2;
	my $p1 = ($mediay - $sizey)/2;

	my @posterbb = ($p0,$p1,$p0+$sizex,$p1+$sizey);
	
	print $ohandle "%%Pages: ",$nrows*$ncols,"\n";
	print $ohandle "%%DocumentMedia: $args{-media} ",int($mediasize[2])," ",int($mediasize[3])," 0 white ()\n";
	print $ohandle "%%BoundingBox: 0 0 ",int($mediasize[2])," ",$mediasize[3],"\n";
	print $ohandle "%%EndComments\n\n";
	print $ohandle "% Print poster $args{-infile} in $nrows","x$ncols tiles with ",sprintf("%.3g",$scale)," magnification\n";

	print $ohandle "%%BeginProlog\n";

	printf $ohandle "/cutmark	%% - cutmark -\n".
		"{		%% draw cutline\n".
		"	0.23 setlinewidth 0 setgray\n".
		"	clipmargin\n".
		"	dup 0 moveto\n".
		"	dup neg leftmargin add 0 rlineto stroke\n".
		"	%% draw sheet alignment mark\n".
		"	dup dup neg moveto\n".
		"	dup 0 rlineto\n".
		"	dup dup lineto\n".
		"	0 rlineto\n".
		"	closepath fill\n".
		"} bind def\n\n";

	printf $ohandle "%% usage: 	row col tileprolog ps-code tilepilog\n".
		"%% these procedures output the tile specified by row & col\n".
		"/tileprolog\n".
		"{ 	%%def\n".
		"	gsave\n".
		"       leftmargin botmargin translate\n".
	        "	do_turn {exch} if\n".
		"	/colcount exch def\n".
		"	/rowcount exch def\n".
		"	%% clip page contents\n".
		"	clipmargin neg dup moveto\n".
		"	pagewidth clipmargin 2 mul add 0 rlineto\n".
		"	0 pageheight clipmargin 2 mul add rlineto\n".
		"	pagewidth clipmargin 2 mul add neg 0 rlineto\n".
		"	closepath clip\n".
		"	%% set page contents transformation\n".
		"	do_turn\n".
	        "	{	pagewidth 0 translate\n".
		"		90 rotate\n".
	        "	} if\n".
		"	pagewidth colcount 1 sub mul neg\n".
		"	pageheight rowcount 1 sub mul neg\n".
	        "	do_turn {exch} if\n".
		"	translate\n".
	        "	posterxl posteryb translate\n".
		"	sfactor dup scale\n".
	        "	imagexl neg imageyb neg translate\n".
		"	tiledict begin\n".
	        "	0 setgray 0 setlinecap 1 setlinewidth\n".
	        "	0 setlinejoin 10 setmiterlimit [] 0 setdash newpath\n".
	        "} bind def\n\n";

	printf $ohandle "/tileepilog\n".
	        "{	end %% of tiledict\n".
	        "	grestore\n".
	        "	%% print the cutmarks\n".
	        "	gsave\n".
		"       leftmargin botmargin translate\n".
	        "	pagewidth pageheight translate cutmark 90 rotate cutmark\n".
	        "	0 pagewidth translate cutmark 90 rotate cutmark\n".
	        "	0 pageheight translate cutmark 90 rotate cutmark\n".
	        "	0 pagewidth translate cutmark 90 rotate cutmark\n".
	        "	grestore\n".
	        "	%% print the page label\n".
	        "	0 setgray\n".
	        "	leftmargin clipmargin 3 mul add clipmargin labelsize add neg botmargin add moveto\n".
	        "	(Grid \\( ) show\n".
	        "	rowcount strg cvs show\n".
	        "	( , ) show\n".
	        "	colcount strg cvs show\n".
	        "	( \\)) show\n".
	        "	showpage\n".
                "} bind def\n\n";

	print $ohandle "%%EndProlog\n\n";
	print $ohandle "%%BeginSetup\n";
	printf $ohandle "%% Try to inform the printer about the desired media size:\n".
	        "/setpagedevice where 	%% level-2 page commands available...\n".
	        "{	pop		%% ignore where found\n".
	        "	3 dict dup /PageSize [ %d %d ] put\n".
	        "	dup /Duplex false put\n%s".
	        "	setpagedevice\n".
                "} if\n",
	       int($mediasize[2]),int($mediasize[3]),
	       0?"       dup /ManualFeed true put\n":"";	# $manualfeed ?

	printf $ohandle "/sfactor %.10f def\n".
	        "/leftmargin %d def\n".
	        "/botmargin %d def\n".
	        "/pagewidth %d def\n".
	        "/pageheight %d def\n".
	        "/imagexl %d def\n".
	        "/imageyb %d def\n".
	        "/posterxl %d def\n".
	        "/posteryb %d def\n".
	        "/do_turn %s def\n".
	        "/strg 10 string def\n".
	        "/clipmargin 6 def\n".
	        "/labelsize 9 def\n".
	        "/tiledict 250 dict def\n".
	        "tiledict begin\n".
	        "%% delay users showpage until cropmark is printed.\n".
	        "/showpage {} def\n".
		"/setpagedevice { pop } def\n".
	        "end\n",
	        $scale, int($cutmargin[0]), int($cutmargin[1]),
	        int($mediasize[2]-2*$cutmargin[0]),int($mediasize[3]-2*$cutmargin[1]),
	        int($imagebb[0]),int($imagebb[1]),int($posterbb[0]),int($posterbb[1]),
	        $rotate?"true":"false";

	print $ohandle "/Helvetica findfont labelsize scalefont setfont\n";

	print $ohandle "%%EndSetup\n";

	my $tail_cntl_D = 0;  my $page = 1;
	for my $row (1..$nrows) {
		for my $col (1..$ncols) {
			print $ohandle "\n%%Page: $page $page\n";
			print $ohandle "$row $col tileprolog\n";
			print $ohandle "%%BeginDocument: $args{-infile}\n";
			
			$ihandle->seek(0,0);

			my $bp = 0;
			my @buf = ();
			$buf[$bp] = <$ihandle>;

			while ($buf[1-$bp] = <$ihandle>) {
				print $ohandle $buf[$bp] if $buf[$bp] !~ /^%/;
				$bp = 1-$bp;
			}
			if ($buf[$bp] =~ s/\x4//) { ++$tail_cntl_D; }

			print $ohandle $buf[$bp] if $buf[$bp] !~ /^%/ and $buf[$bp];

			print $ohandle "\n%%EndDocument\n";
			print $ohandle "tileepilog\n";

			++$page;
		}
	}

	print $ohandle "%%EOF\n";

	printf $ohandle "%c",0x4 if $tail_cntl_D;

	undef $obj->{oh};  undef $obj->{ih};

}

%mediatable = (
	 LETTER =>    '612,792',
	 LEGAL =>     '612,1008',
	 TABLOID =>   '792,1224',
	 LEDGER =>    '792,1224',
	 EXECUTIVE => '540,720',
	 MONARCH =>   '279,540',
	 STATEMENT => '396,612',
	 FOLIO =>     '612,936',
	 QUARTO =>    '610,780',
	 C5 =>        '459,649',
	 B4 =>        '729,1032',
	 B5 =>        '516,729',
	 DL =>        '312,624',
	 A0 => 	      '2380,3368',
	 A1 => 	      '1684,2380',
	 A2 => 	      '1190,1684',
	 A3 => 	      '842,1190',
	 A4 =>        '595,842',
	 A5 => 	      '420,595',
	 A6 => 	      '297,421',
	 P =>         '1,1',
	 I =>         '72,72',
	 FT =>        '864,864',
	 MM =>        '2.83465,2.83465',
	 CM =>        '28.3465,28.3465',
	 M =>         '2834.65,2834.65');

# box_convert: convert user textual box spec into numbers in ps units
#              box = [fixed x fixed][+ fixed , fixed] unit
#              fixed = digits [ . digits]
#              unit = medianame | i | cm | mm | m | p
sub box_convert {
	my $obj = shift;
	my $origspec = shift;

	my $boxspec = uc $origspec;

	my @psbox = ();

	my $mx = 1;  my $my = 1;  my $ox = 0;  my $oy = 0;

	# parsing fixed x fixed
	if ($boxspec =~ s/^\s*(\d+(?:\.\d+)?)\s*[x*]\s*(\d+(?:\.\d+)?)\s*//) {
		$mx = $1;  $my = $2;
	}

	# parsing +fixed,fixed
	if ($boxspec =~ s/^+(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*//) {
		$ox = $1;  $oy = $2;
	}

	# parsing media or units
	my $n = 0;
	my $key = '';
	if ($mediatable{$boxspec}) {
		$n = 1;  $key = $boxspec;
	} else {
		for (keys %mediatable) {
			if ($boxspec =~ /$_/) { ++$n;  $key = $_; }
		}
	}

	die "Your box spec $boxspec is not unique! (give more chars)" if $n > 1;
	die "I don't understand your box specification $boxspec" unless $n;

	my ($ux,$uy) = (1,1);
	if ($mediatable{$key} =~ /^(.*),(.*)$/) { ($ux,$uy) = ($1,$2); }

	@psbox = ( $ox * $ux, $oy * $uy, $mx * $ux, $my * $uy );

	for (0..1) {
		if ($psbox[$_] < 0 or $psbox[$_+2] < $psbox[$_]) {
			die "Your specification $boxspec leads to negative values!";
		}
	}

#	print "Box convert: $origspec into [",join(',',@psbox),"].\n";

	return @psbox;
}

sub margin_convert {
	my $obj = shift;
	my $origspec = shift;

	my $marginspec = uc $origspec;

	my @margin = ();

	# not specified
	unless ($marginspec) {
		@margin = (0,0);
	} elsif ($marginspec =~ /^(.*)%$/) {	# percent
		@margin = (.01 * $1 * $obj->{mediasize}->[2],
				.01 * $1 * $obj->{mediasize}->[3]);
	} else {	# absolute
		my @marg = $obj->box_convert($marginspec);
		@margin = ($marg[2],$marg[3]);
	}

	for (0..1) {
		if ($margin[$_] < 0 or 2*$margin[$_] >= $obj->{mediasize}->[$_+2]) {
			die "Margin value $origspec out of range!";
		}
	}

#	print "Margin convert: $origspec into [",join(',',@margin),"].\n";

	return @margin;
}

1;

__END__

=head1 VERSION

0.02

=head1 AUTHOR

(c) 2001-02 Milan Sorm, sorm@pef.mendelu.cz
at Faculty of Economics,
Mendel University of Agriculture and Forestry in Brno, Czech Republic.

This module was needed for making SchemaView Plus (C<svplus>).

=head1 SEE ALSO

perl(1), svplus(1).

=cut

