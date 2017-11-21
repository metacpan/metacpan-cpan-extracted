#!/usr/bin/perl -w

use strict;
use GD::Simple;
use Getopt::Long;

# always prefer local version of module
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

my $load;
my %opt = (width => 600, height => 200, trim => 0);
my %colors = (
	tail => "darkgray",
	q1 => "darkcyan", q2 => "orange", q3 => "darkcyan", q4 => "orange",
	scale => "darkred", mean => "black",
);
my %cut;

# Don't require module just in case
GetOptions (
	'b|base=s'   => \$opt{base},
	'f|floor=s'  => \$opt{zero},
	'w|width=s'  => \$opt{width},
	'h|height=s' => \$opt{height},
	'ltrim=s'    => \$cut{ltrim},
	'utrim=s'    => \$cut{utrim},
	'min=s'      => \$cut{min},
	'max=s'      => \$cut{max},
	'noize=s'    => \$cut{noize_thresh},
	'l|load=s'   => \$load,
	'help'       => \&usage,
) or usage();

sub usage {
	print STDERR <<"EOF";
Usage: $0 [options] pic.png
Read numbers from STDIN, output histogram as a png file.
Options may include:
  --width <nnn>
  --height <nnn> - size of picture
  --base <1 + small o> - relative precision of underlying engine
  --floor <positive number> - count all below this as zero
  --ltrim <0..100> - cut that % off from the left
  --utrim <0..100> - cut that % off from the right
  --min <xxx> - strip data below this value
  --max <xxx> - strip data above this value
  --noize <xxx> - strip bins with hit counts below this
  --load, -l - load data from a JSON file
  --help - this message
EOF
	exit 2;
};

# Where to write the pic
my $out = shift;

defined $out or die "No output file given";
my $fd;
if ($out eq '-') {
	$fd = \*STDOUT;
} else {
	open ($fd, ">", $out) or die "Failed to open $out: $!";
};

# sane default for precision = 1 pixel at right/left side
$opt{base} = 1+1/$opt{width} unless defined $opt{base};

my $stat;
if (defined $load) {
	eval { require JSON::XS; 1 }
		or die "JSON::XS is required for --load option to work\n";
	my $fd;
	if ($load eq '-') {
		$fd = \*STDIN;
	} else {
		open ($fd, "<", $load)
			or die "Failed to r-open $load: $!";
	};
	local $/;
	defined (my $json = <$fd>) or die "Failed to read from $load: $!";
	close $fd;
	my $raw = JSON::XS::decode_json($json);
	$stat = Statistics::Descriptive::LogScale->new(%$raw);
} else {
	$stat = Statistics::Descriptive::LogScale->new(
		base => $opt{base}, linear_width => $opt{zero});
	my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;
	while (<STDIN>) {
		$stat->add_data(/($re_num)/g);
	};
};

if (!$stat->count) {
	warn "No data was given, aborting.\n";
	exit 3;
};

# Let's do the real work
if (%cut) {
	$stat = $stat->clone(%cut);
};
my ($width, $height) = @opt{"width", "height"};
my $hist = $stat->histogram( count => $width, normalize_to => $height);

# some additional query data
my @mean = map {
	($_ - $stat->min) * $width / ($stat->max - $stat->min)
} ($stat->mean-$stat->std_dev, $stat->mean, $stat->mean+$stat->std_dev );

# calculate font size
my $fontsize = $width/75;
$fontsize = 8 if $fontsize < 8;

# draw!
my $gd = GD::Simple->new($width, $height);
$gd->fontsize( $fontsize );
$gd->font( "Times" );
$gd->bgcolor('white');
$gd->clear;

# draw scale
my $scale = 10;
$gd->fgcolor( $colors{scale} );
foreach (1 .. ($scale-1)) {
	$gd->line( $width * ($_/$scale), 0, $width * ($_/$scale), $height );
};

# Determine some colorful features
my $i=0;
my @q_switch = map { $stat->percentile($_) } 0.5,25,50,75,99.5;
my @colorlist = @colors{qw{tail q1 q2 q3 q4 tail}};
my $colornum  = 0;

# plot!
foreach (@$hist) {
	if ($q_switch[$colornum] and $_->[1] > $q_switch[$colornum] ) {
		$colornum++;
	};
	$gd->fgcolor( $colorlist[$colornum] );
	$gd->line($i, $height, $i, $height-$_->[0]);
	$i++;
};

# mention mean/stdev, too
$gd->fgcolor( $colors{mean} );
$gd->line( $mean[0], $height*0.9,  $mean[2], $height*0.9  );
$gd->line( $mean[1], $height,      $mean[1], $height*0.8  );
$gd->line( $mean[0], $height*0.95, $mean[0], $height*0.85 );
$gd->line( $mean[2], $height*0.95, $mean[2], $height*0.85 );
$gd->moveTo( $mean[1], $height-5 );
$gd->string( sprintf( "mean=%0.3g, stdev=%0.3g", $stat->mean, $stat->std_dev ));

# finally, print digits (do it AFTER the plotting)
my $min = $hist->[0][1];
my $max = $hist->[-1][2];
my $range = $max - $min;

foreach (0 .. ($scale-1)) {
	$gd->fgcolor( $colors{scale} );
	$gd->moveTo( $width * ($_/$scale) + 2, $fontsize+2 );
	$gd->string( sprintf("%0.3g", $min + $range*$_/$scale) );
};

# all folks
print $fd $gd->png;
