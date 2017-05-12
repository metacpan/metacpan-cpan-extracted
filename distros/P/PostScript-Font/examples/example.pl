#!/usr/local/bin/perl -w
my $RCS_Id = '$Id: example.pl,v 1.3 1999/10/30 17:01:26 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Thu May 13 15:59:04 1999
# Last Modified By: Johan Vromans
# Last Modified On: Sat Oct 30 18:59:45 1999
# Update Count    : 195
# Status          : Unknown, Use with caution!

################ Common stuff ################
#
# This program shows how to use the modules PostScript::Resources,
# PostScript::Font and PostScript::FontMetrics to perform some basic
# typesetting.
#
# It is for demonstration purposes only, and does not pretend to mimic
# a real typesetting program.

use strict;
use lib qw(lib);
use PostScript::Resources;
use PostScript::Font;
use PostScript::FontMetrics;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Command line parameters ################

my $fontname = "CharterBT-Roman";
my $fontsize = 14;

use Getopt::Long 2.13;
sub app_options();

my $verbose = 0;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test (no actual processing)

app_options();

# Options post-processing.
$trace |= ($debug || $test);
$verbose |= $trace;

# Options for PostScript:: modules.
my @opts = ( debug => $debug, trace => $trace, verbose => $verbose );

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || '/usr/tmp';

################ The Process ################

# Load the UPR file(s).
my $psres = new PostScript::Resources;

# Load the Outline info.
my $fontfile = $psres->FontOutline ($fontname);
die ("No Outline info for $fontname\n") unless defined $fontfile;
my $fontinfo = new PostScript::Font ($fontfile, @opts);
die ("$fontfile: Not a recognized font file\n") unless defined $fontinfo;

# Get the font scale (usually 1000).
my $fontscale = 1000;
$fontscale = int(1/$fontinfo->FontMatrix->[0]);

# Load the metrics info.
my $metricsfile = $psres->FontAFM ($fontname);
unless ( defined $metricsfile ) {
    # If it is a True Type font, we can use the Outline to get at the metrics.
    $metricsfile = $fontfile
      if $fontinfo->Type eq 't';
}
die ("No font metrics info for $fontname\n") unless defined $metricsfile;
my $metrics = new PostScript::FontMetrics ($metricsfile, @opts);
die ("$metricsfile: Not a recognized metrics file\n") unless defined $metrics;

# Start output. PostScript preamble.
print STDOUT <<EOD;
%!PS-Adobe-3.0
%%Title (Demo of PostScript::Font modules)
%%Pages: 1
%%DocumentProvidedResources: font $fontname
%%EndComments
%%BeginProlog
%%BeginResource: font $fontname
${\$fontinfo->FontData}
%%EndResource
% TJ operator to print typesetinfo vectors.
% Requires Fpt to be defined!
/TJ {
  { dup type /stringtype eq { show } { Fpt mul 0 rmoveto } ifelse }
  forall
} bind def
% Latin1 reencoding of $fontname.
/$fontname-Latin1
  /$fontname findfont
  30 dict begin
  { 1 index /FID eq { pop pop } { def } ifelse} forall
  /Encoding ISOLatin1Encoding def
  currentdict end
definefont
% show right-aligned string
/rshow { dup stringwidth pop neg 0 rmoveto show } bind def
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
EOD

# Print some test strings.

my $typesetinfo =
  $metrics->kstring ("Demonstration of PostScript::Font modules");

@ARGV = "(LVATA\\D) ( L V A T A \\ D )" unless @ARGV;

my $x0 = 50;			# left margin
my $x1 = 550;			# right margin
my $y0 = 600;			# top margin
my $y = $y0;			# current vertical pos
my $lineskip = 1.4*$fontsize;	# distance between base of lines

# Show title.
print STDOUT ("$x0 $y moveto\n");
print STDOUT ("/$fontname findfont ",
	      1.5*$fontsize, " scalefont setfont\n");
textline ($typesetinfo, $fontsize, $fontscale);
$y -= 2*$lineskip;

# Show argument, unmodified.
print STDOUT ("/$fontname findfont $fontsize scalefont setfont\n");
print STDOUT ("$x0 $y moveto (", psstr(@ARGV), ") show\n");
print STDOUT ("$x1 $y moveto (no kerning) rshow\n");

# Show argument, with different kernings.
for my $extend ( undef, 0, 100 ) {
    my $typesetinfo = $metrics->kstring ("@ARGV", $extend);
    print STDERR ("[ @$typesetinfo ]\n") if $debug;
    $y -= $lineskip;
    print STDOUT ("$x0 $y moveto\n");
    textline ($typesetinfo, $fontsize, $fontscale);
    print STDOUT ("$x1 $y  moveto (kerning");
    print STDOUT (", extend = $extend") if defined $extend;
    print STDOUT (") rshow\n");
}

# Produce some text blocks.
# Switch to ISOLatin1Encoding.
$metrics->setEncoding (PostScript::Font::ISOLatin1Encoding());
$metrics->{fontname} .= "-Latin1";
print STDOUT ("/", $metrics->FontName, " findfont ",
	      "$fontsize scalefont setfont\n");

$y = textblock ($metrics, $fontsize, $fontscale, $lineskip,
		$x0, $y-2*$lineskip, $x1-$x0, <<EOD);
Sommige mensen hebben de dood aan den lijve ervaren. Ze zijn klinisch
morsdood geweest. In hun lichamelijke doodstoestand ervoeren ze, los
van hun lichaam geraakt, een ongekend geluk, dat hen sterker aantrok
dan de genegenheid van hun geliefden. Maar een gevoel van
verantwoordelijkheid tegenover diegenen onder deze geliefden die zich
in het aardse leven van hen afhankelijk voelden, dreef hen in hun
lichaam terug.
EOD

$y = textblock ($metrics, $fontsize, $fontscale, $lineskip,
		$x0, $y-1.5*$lineskip, $x1-$x0, <<EOD);
Uit de dood herrezen getuigen ze van het ervaren geluk. Die ervaring
is zo werkelijk voor hen dat hun hele leven erdoor verandert. Ze
hebben geen enkele angst voor de dood meer. Ze verlangen zelfs naar
het uur waarin ze, na hun aardse plicht gedaan te hebben, definitief
zullen mogen sterven. Ze merken echter dat de meeste mensen aan wie ze
hun verhaal vertellen hen aankijken alsof ze gek geworden zijn.
Daardoor zijn ze ertoe geneigd het stilzwijgen over hun ervaring te
bewaren.
EOD

$y = textblock ($metrics, $fontsize, $fontscale, $lineskip,
		$x0, $y-1.5*$lineskip, $x1-$x0, <<EOD);
Een enkele ziekenhuisarts registreert het relaas van patiënten die hij
uit de dood ziet terugkomen. Zijn werk voltrekt zich in de marge van
het wetenschappelijk onderzoek. Want getuigenissen, zo oordeelt men,
ook al ondersteunen ze elkaar onafhankelijk op alle punten, zijn
slechts aanwijzingen, geen meetbare feiten. Dus.
EOD

# PostScript trailer
print STDOUT <<EOD;
showpage
%%Trailer
%%EOF
EOD

exit 0;

################ Subroutines ################

# Provide escapes for a PostScript text.
sub psstr {
    my ($arg) = @_;
    $arg =~ s/([\(\)\\]|[^\040-\176])/sprintf("\\%o",ord($1))/eg;
    $arg;
}

# Print a typesetting vector. Explicit.
sub xtextline {
    my ($t, $fontsize, $fontscale) = @_;
    foreach ( @$t ) {
	if ( /^\(/ ) {
	    print STDOUT ($_, " show\n");
	}
	else {
	    printf STDOUT ("%.3f 0 rmoveto\n", ($_*$fontsize)/$fontscale);
	}
    }
}

# Print a typesetting vector. Use TJ definition.
sub textline {
    my ($t, $fontsize, $fontscale) = @_;
    print STDOUT ("/Fpt ", $fontsize/$fontscale, " def\n",
		  "[");
    my $l = 1;
    foreach ( @$t ) {
	$_ = sprintf("%.3g", $_) unless /^\(/;
	if ( ($l += length) >= 80 ) {
	    print STDOUT ("\n ");
	    $l = 1 + length;
	}
	print STDOUT ($_);
    }
    print STDOUT ("] TJ\n");
}

sub textblock {
    my ($metrics, $fontsize, $fontscale, $lineskip,
	$x, $y, $width,
	@text) = @_;

    my $scale = $fontsize / $fontscale;

    # Width of a space.
    my $wspace = $metrics->stringwidth(" ") * $scale;
    my $wd = -$wspace;

    my @res;

    # Split into space-separated pieces (let's call them "words").
    @text = split (/\s+/, join (" ", @text));
    foreach my $str ( @text ) {
	# Width of this "word".
	my $w = $metrics->kstringwidth ($str) * $scale;
	# See if it fits.
	if ( $wd + $wspace + $w > $width ) {
	    # No -> fill what we have.
	    my $ext = (($width - $wd) / (@res-1)) / $scale;
	    my $t = $metrics->kstring ("@res", $ext);
	    print STDOUT ("% @res\n");
	    print STDOUT ("$x $y moveto\n");
	    print STDERR ("[ @$t ]\n") if $debug;
	    textline ($t, $fontsize, $fontscale);
	    # Advance to next line.
	    $y -= $lineskip;
	    # Reset.
	    @res = ();
	    $wd = -$wspace;
	}
	# It fits -> append.
	$wd += $wspace + $w;
	push (@res, $str);
    }
    # Process remainder.
    if ( @res ) {
	my $t = $metrics->kstring ("@res");
	print STDOUT ("% @res\n");
	print STDOUT ("$x $y moveto\n");
	textline ($t, $fontsize, $fontscale);
    }
    # Return y coordinate of last line printed.
    $y;
}

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;
    
    if ( !GetOptions(
		     'font=s'	=> \$fontname,
		     'fontsize=i'	=> \$fontsize,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident if $ident;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    -font XXX		font to use
    -fontsize		font size
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit $exit if $exit != 0;
}
