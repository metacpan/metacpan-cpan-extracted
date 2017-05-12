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

# Don't require module just in case
GetOptions (
	'b|base=s' => \$opt{base},
	'f|floor=s' => \$opt{zero},
	'w|width=s' => \$opt{width},
	'h|height=s' => \$opt{height},
	'ltrim=s' => \$opt{ltrim},
	'utrim=s' => \$opt{utrim},
	'min=s' => \$opt{min},
	'max=s' => \$opt{max},
	'l|load=s' => \$load,
	'help' => \&usage,
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
		open (my $fd, "<", $load)
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
my ($width, $height) = @opt{"width", "height"};
my $hist = $stat->histogram( %opt, count => $width, normalize_to => 1);

# draw!
my $gd = GD::Simple->new($width, $height);
$gd->bgcolor('white');
$gd->clear;

# draw scale
my $scale = 10;
foreach (1 .. ($scale-1)) {
	$gd->fgcolor( 'blue' );
	$gd->line( $width * ($_/$scale), 0, $width * ($_/$scale), $height );
};

# plot data
my $i=0;
foreach (@$hist) {
	$gd->fgcolor( 'orange');
	$gd->line($i, $height, $i, $height*(1-$_->[0]));
	$i++;
};

# finally, print digits (do it AFTER the plotting)
my $min = $hist->[0][1];
my $max = $hist->[-1][2];
my $range = $max - $min;

foreach (0 .. ($scale-1)) {
	$gd->fgcolor( 'blue' );
	$gd->moveTo( $width * ($_/$scale) + 2, 10 );
	$gd->fontsize( 8 );
	$gd->font( "Times" );
	$gd->string( sprintf("%0.1f", $min + $range*$_/$scale) );
};

# all folks
print $fd $gd->png;
