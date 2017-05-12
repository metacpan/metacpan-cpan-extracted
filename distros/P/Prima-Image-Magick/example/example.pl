use lib qw(./blib/lib ./blib/arch);
use Prima qw(Application ImageViewer Label);
use Image::Magick;
use Prima::Image::Magick qw(:all);

my $p = Prima::Image-> new( width => 10, height => 10);

$p-> begin_paint;
$p-> clear;
$p-> line(0,0,9,9);
$p-> line(0,9,9,0);
$p-> end_paint;

my @types;
my $o = $p-> dup;
$o-> size( 100, 100);
push @types, [ $o, 'linear' ];

my $adaptive = $p-> dup;
$adaptive-> AdaptiveResize( width => 100, height => 100);
push @types, [ $adaptive, 'adaptive' ];

my $gaussian = $p-> dup;
$gaussian-> Resize( width => 100, height => 100, filter => 'Gaussian');
push @types, [ $gaussian, 'gaussian' ];

my $cubic = $p-> dup;
$cubic-> Resize( width => 100, height => 100, filter => 'Cubic');
push @types, [ $cubic, 'cubic' ];

Prima::MainWindow-> new(
	text => 'Prima::Image::Magick demo',
)-> insert( map { 
	[ 'Prima::Label'       => 
		pack  => { expand => 1, fill => 'both' }, 
		text  => "$$_[1] scaling"
	], [ 'Prima::ImageViewer' => 
		pack  => { expand => 1, fill => 'both' }, 
		image => $$_[0]
	] } @types
);

run Prima;
