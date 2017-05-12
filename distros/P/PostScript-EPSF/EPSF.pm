package PostScript::EPSF;

use strict;
use vars qw($VERSION @EXPORT @EXPORT_OK);

$VERSION = "0.01";

require Exporter;
*import = \*Exporter::import;

@EXPORT=qw(include_epsf);
@EXPORT_OK=qw(epsf_prolog);


sub epsf_prolog
{
    use vars qw($EPSF_PROLOG_DONE);
    print <<"EOT" unless $EPSF_PROLOG_DONE++;

/BeginEPSF {
  /b4_Inc_state save def
  /dict_count countdictstack def
  /op_count count 1 sub def
  userdict begin
  /showpage {} def
  0 setgray 0 setlinecap 1 setlinewidth 0 setlinejoin
  10 setmiterlimit [] 0 setdash newpath
  /languagelevel where
  {
     1 ne {
	 false setstrokeadjust
         false setoverprint
     } if
  } if
} bind def

/EndEPSF {
  count op_count sub {pop} repeat
  countdictstack dict_count sub {end} repeat
  b4_Inc_state restore
} bind def

EOT
}


sub include_epsf
{
    my %para;
    while (my($k,$v) = splice(@_, 0, 2)) {
	$k =~ s/^-//;
	$para{$k} = $v;
    }

    #use Data::Dumper; print STDERR Dumper(\%para);

    my $file = delete $para{"file"} ||
	die "Mandatory -file argument is missing";
    

    local(*EPS);
    open(EPS, $file) || die "Can't open $file: $!";
    my($llx, $lly, $urx, $ury);
    my @eps;
    while (<EPS>) {
	if (/^%%BoundingBox:\s*(.*)/) {
	    ($llx, $lly, $urx, $ury) = split(' ', $1);
	} elsif (/^\s*%/ || /^\s*$/) {
	    # always skip other comments and empty lines
	} else {
	    push(@eps, $_);
	}
    }
    close(EPS);
    die "Missing Bounding box in $file" unless defined $ury;



    my $xscale = delete $para{"xscale"};
    my $yscale = delete $para{"yscale"};

    # Calculate width/height of included file
    my $w = $urx - $llx;
    my $h = $ury - $lly;

    if (my $width = delete $para{"width"}) {
	$xscale = $width / $w;
    }

    if (my $height = delete $para{"height"}) {
	$yscale = $height / $h;
    }
    
    if (my $scale = delete $para{"scale"}) {
	for ($xscale, $yscale) {
	    $_ = $scale unless $_;
	}
    }

    $xscale = $yscale if $yscale && !$xscale;
    $yscale = $xscale if $xscale && !$yscale;

    if ($xscale) {
	$w = $w * $xscale;
	$h = $h * $yscale;
    }

    if (my $pos = delete $para{"pos"}) {
	$pos =~ s/^\s*//;
	@para{"x", "y"} = split(/\s*[,\s]\s*/, $pos);
    }
    my $x = delete $para{"x"} || 0;
    my $y = delete $para{"y"} || 0;

    my $anchor = delete $para{"anchor"} || "c";
    if ($anchor =~ /w/) {
	# no need to adjust $x
    } elsif ($anchor =~ /e/) {
	$x -= $w;
    } else {
	$x -= $w/2;
    }
    if ($anchor =~ /s/) {
	# no need to adjust $y
    } elsif ($anchor =~ /n/) {
	$y -= $h;
    } else {
	$y -= $h/2;
    }

    my $rotate = delete $para{"rotate"};

    my $clip       = delete $para{"clip"};
    my $background = delete $para{"background"};
    my $boarder    = delete $para{"boarder"} || 0;

    if ($^W && %para) {
	for (sort keys %para) {
	    warn "Unrecognized parameter: -$_ => $para{$_}\n";
	}
    }

    epsf_prolog();

    print "\nBeginEPSF\n";
    if ($rotate || $xscale || $clip || $background) {
	print "$x $y translate\n";
	print "$rotate rotate\n" if $rotate;
	if ($clip || $background) {
	    my $llx = 0;
	    my $lly = 0;
	    my $urx = $w;
	    my $ury = $h;
	    if ($boarder) {
		$llx -= $boarder;
		$lly -= $boarder;
		$urx += $boarder;
		$ury += $boarder;
	    }
	    print "$llx $lly moveto $urx $lly lineto\n";
	    print "$urx $ury lineto $llx $ury lineto closepath\n";
	    print "clip\n" if $clip;
	    if ($background) {
		print "gsave ", color_to_ps($background), " fill grestore\n";
	    }
	    print "newpath\n";
	}
	print "$xscale $yscale scale\n" if $xscale;
	print 0-$llx, " ", 0-$lly, " translate\n";
    } else {
	print $x-$llx, " ", $y-$lly, " translate\n";
    }

    print "%%BeginDocument: $file\n";
    print @eps;
    print "%%EndDocument: $file\n";
    print "EndEPSF\n\n";

}

BEGIN
{
    use vars qw(%color_names);
    %color_names = (
	black   => 0,
	white   => 1,

        red     => "#f00",
	green   => "#0f0",
        blue    => "#00f",
        yellow  => "#ff0",
	magenta => "#f0f",
        cyan    => "#0ff",
    );
}


# should probably go into it's own module
sub color_to_ps
{
    my $color = lc(shift || "");
    $color =~ s/^\s+//;
    $color =~ s/\s+$//;

    $color = $color_names{$color} || $color;

    if ($color =~ /^\d+(?:\.\d+)?$/) {
	$color = 1 if $color > 1;
	return sprintf "%.3f setgray", $color;
    }

    if ($color =~ /^\#([0-9a-f]+)$/ && (length($1) % 3) == 0) {
	my $len = int(length($1) / 3);
	my $fff = 2 ** ($len*4) - 1;
	$color = $1;
	my @rgb;
	while (length $color) {
	    push(@rgb, hex(substr($color, 0, $len)) / $fff);
	    substr($color, 0, $len) = '';
	}
	return join(" ", map {sprintf "%.3f", $_} @rgb), " setrgbcolor";
    }

    return;  # did not understand
}

1;
