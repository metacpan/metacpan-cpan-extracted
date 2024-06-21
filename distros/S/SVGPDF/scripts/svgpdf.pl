#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Wed Jul  5 09:14:28 2023
# Last Modified By: 
# Last Modified On: Fri Jun 21 10:26:29 2024
# Update Count    : 244
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use utf8;

# Package name.
my $my_package = 'SVGPDF';
# Program name and version.
my ($my_name, $my_version) = qw( svgpdf 0.081 );

use FindBin;
use lib "$FindBin::Bin/../lib";

my @pgsz = ( 595, 842 );	# A4

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $output = "__new__.pdf";
my $api = "PDF::API2";		# or PDF::Builder
my $pagesize;
my $ppi = 96;			# pixels per inch
my $fontsize = 12;		# design
my $background;
my $wstokens = 0;
my $combine = "none";		# combine multiple into one
my $grid;			# add grid
my $prog;			# generate program
my $verbose = 1;		# verbose processing
my $ident;			# show version

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 1;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= $debug;
$test  |= $debug;

################ Presets ################

################ The Process ################

eval "require $api;"     || die($@);
# SVGPDF may redefine some PDF:XXX modules.
eval "require SVGPDF;" || die($@);
app_ident() if $ident;

my $pdf = $api->new;
$api->add_to_font_path($ENV{HOME}."/.fonts");

my $page;
my $gfx;
my $x;
my $y;

sub newpage {
    $page = $pdf->page;
    $page->size( [ 0, 0, @pgsz ] );
    $gfx = $page->gfx;
    $x = 10;
    $y = $pgsz[1]-10;
    if ( $background ) {
	$gfx->save;
	$gfx->rectangle( 0, 0, @pgsz );
	$gfx->fillcolor($background);
	$gfx->fill;
	$gfx->restore;
    }
}
newpage();

foreach my $file ( @ARGV ) {
    my $p = SVGPDF->new
      ( pdf => $pdf,
	atts => { debug    => $debug,
		  verbose  => $verbose,
		  grid     => $grid,
		  prog     => $prog,
		  pagesize => \@pgsz,
		  fontsize => $fontsize,
		  wstokens => $wstokens,
		  trace    => $trace } );

    $p->process($file, combine => $combine );
    my $o = $p->xoforms;
    warn("$file: SVG objects: ", 0+@$o, "\n") if $verbose;

    my $i = 0;
    foreach my $xo ( @$o ) {
	$i++;
	# use DDumper; DDumper( { %{ $xo }, xo => "XO" } );
	if ( ref($xo->{xo}) eq "SVGPDF::PAST" ) {
	    if ( $prog ) {
		open( my $fd, '>', $prog );
		my $pdf = $prog =~ s/\.pl$/.pdf/r;
		print $fd ( "#! perl\n",
			    "use v5.26;\n",
			    "use utf8;\n",
			    "use $api;\n",
			    "my \$pdf  = $api->new;\n",
			    "my \$page = \$pdf->page;\n",
			    "my \$xo   = \$page->gfx;\n",
			    "my \$font = \$pdf->font('Times-Roman');\n",
			    "\n",
			    $xo->{xo}->prog,
			    "\n\$pdf->save('$pdf');\n" );
		close($fd);
	    }
	    $xo->{xo} = $xo->{xo}->xo;
	}
	my @bb = @{$xo->{bbox}};
	my $w = $bb[2]-$bb[0];
	my $h = $bb[3]-$bb[1];

	# SVG units are pixels @96ppi. 10cm = 378px = 283pt.
	my $xscale = 72/$ppi;
	my $yscale = 72/$ppi;

	if ( $xo->{vwidth} ) {
	    $xscale *= $xo->{vwidth} / $w;
	}
	if ( $xo->{vheight} ) {
	    $yscale *= $xo->{vheight} / $h;
	}
	if ( $w*$xscale > $pgsz[0] ) {
	    my $scale = $pgsz[0]/$w*$xscale;
	    $xscale *= $scale;
	    $yscale *= $scale;
	}
	if ( $h*$yscale > $pgsz[1] ) {
	    my $scale = $pgsz[1]/$h*$yscale;
	    $xscale *= $scale;
	    $yscale *= $scale;
	}

	newpage() if $y - $h * $yscale < 0;
	warn(sprintf("object %d [ %.2f, %.2f %s] ( %.2f, %.2f, %.2f, %.2f @%.g,%.g )\n",
		     $i, $w, $h,
		     $xo->{vwidth}
		     ? sprintf("=> %.2f, %.2f ", $xo->{vwidth}, $xo->{vheight})
		     : "",
		     $x, $y-$h*$yscale, $w, $h, $xscale, $yscale ))
	  if $verbose;
	$gfx->object( $xo->{xo}, $x-$bb[0]*$xscale,
		      $y-($bb[1]+$h)*$yscale, $xscale, $yscale );
	if ( $test ) {
	    crosshairs( $gfx, $x, $y, "green" );
	    crosshairs( $gfx, $x+$bb[2]*$xscale, $y-$bb[3]*$yscale, "magenta" );
	    if ( $bb[0] || $bb[1] ) {
		crosshairs( $gfx, $x-$bb[0]*$xscale, $y-$bb[3]*$yscale, "red" );
	    }
	}
	$y -= $h * $yscale;
    }
    crosshairs( $gfx, $x, $y, "blue" ) if $test;
}

$pdf->save($output);

################ Subroutines ################

sub crosshairs ( $gfx, $x, $y, $col = "black" ) {
    for ( $gfx  ) {
	$_->save;
	$_->line_width(0.1);
	$_->stroke_color($col);
	$_->move($x-20,$y);
	$_->hline($x+300);
	$_->stroke;
	$_->move($x,$y+20);
	$_->vline($y-20);
	$_->stroke;
	$_->restore;
    }
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'output=s' => \$output,
		     'program=s' => \$prog,
		     'grid:i'	=> \$grid,
		     'builder'	=> sub { $api = "PDF::Builder";
					 push( @INC, $ENV{HOME}."/src/PDF-Builder/lib" );
					 },
		     'api=s'	=> \$api,
		     'combine=s' => \$combine,
		     'pagesize=s' => \$pagesize,
		     'ppi=i'    => \$ppi,
		     'fontsize=f' => \$fontsize,
		     'background=s' => \$background,
		     'ws!'	=> \$wstokens,
		     'ident'	=> \$ident,
		     'verbose|v+'	=> \$verbose,
		     'quiet'	=> sub { $verbose = 0 },
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'test!'	=> \$test,
		     'debug+'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    $grid = 5 if defined($grid) && $grid < 5;
    if ( $pagesize ) {
	die("--pagesize requires WIDTHxHEIGHT\n")
	  unless $pagesize =~ /^(\d+)x(\d+)$/;
	@pgsz = ( $1, $2 );
    }
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]",
		  " using SVGPDF $SVGPDF::VERSION\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [svg-file ...]
   --output=XXX		PDF output file name
   --pagesize=WWxHH	pagesize
   --ppi=NN		pixels per inch (default: 96)
   --program=XXX	generates a perl program (single SVG only)
   --api=XXX		uses PDF API (PDF::API2 (default) or PDF::Builder)
   --builder		short for --api=PDF::Builder
   --combine=XXX	combine (none, stacked, bbox)
   --grid=N             provides a grid with spacing N
   --nows               ignore whitespace tokens
   --[no]test		shows position guides (enabled by default)
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

