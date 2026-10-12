use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use InputTest;
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ProgressBar;

sub bar (%args) {
	my $bar = Term::Fabulous::Widget::ProgressBar->new( preferred_columns => 10, %args );
	my $ui  = layout_ui($bar);
	return ( $bar, $ui );
}

subtest 'styles, labels and fractions' => sub {
	my ( $bar, $ui ) = bar( value => 42 );
	is [ $bar->columns, row_text( $bar, 0 ) ], [ 15, "\x{2588}\x{2588}\x{2588}\x{2588}\x{258F}\x{2591}\x{2591}\x{2591}\x{2591}\x{2591}  42%" ],
		'blocks, an eighth block at the edge and the percentage';
	is [ $bar->fraction, $bar->percent, $bar->format_value(50) ], [ 0.42, 42, '50%' ], 'fraction, percent and the format';

	$bar->fractional(0);
	is row_text( $bar, 0 ), ( "\x{2588}" x 4 ) . ( "\x{2591}" x 6 ) . '  42%', 'whole cells without fractions';
	$bar->style('line');
	$bar->value_position('left');
	is row_text( $bar, 0 ), "42%  " . ( "\x{2501}" x 4 ) . ( "\x{2500}" x 6 ), 'the line style, the label on the left';
	$bar->style('ascii');
	$bar->striped(1);
	$bar->value(80);
	is row_text( $bar, 0 ), '80%  ##==##==--', 'ASCII stripes, two cells each';
	$bar->show_value(0);
	is [ row_text( $bar, 0 ), $bar->columns ], [ '##==##==--', 10 ], 'no label';
	$bar->fill_glyph('*');
	is [ row_text( $bar, 0 ), $bar->glyphs ], [ '**==**==--', '*', '-', '=' ], 'a glyph of your own';

	my ( $inside, $inside_ui ) = bar( value => 50, value_position => 'inside', fractional => 0 );
	is [ $inside->columns, row_text( $inside, 0 ) ], [ 10, '   50%    ' ], 'inside: the label over the bar, which is drawn with backgrounds';
	is shown($inside)->cell( 1, 0 )->[2], $inside->color_attr( $inside->color ),             'the filled part is the fill color';
	is shown($inside)->cell( 3, 0 )->[1], $inside->color_attr( $inside->inside_text_color ), 'the label is dark over the fill';
	is shown($inside)->cell( 5, 0 )->[1], $inside->color_attr( $inside->text_color ),        'and light over the track';

	my ( $tall, $tall_ui ) = bar( value => 100, layout => { sizing => { height => sizing_fixed(2) } }, value_format => sub ( $value, $fraction ) { "$value of 100" } );
	is [ map { row_text( $tall, $_ ) } 0, 1 ], [ ( "\x{2588}" x 10 ) . ' 100 of 100', ( "\x{2588}" x 10 ) . ( ' ' x 11 ) ], 'two rows, a code reference label on the first';
};

subtest 'segments' => sub {
	my ( $bar, $ui ) = bar( max => 50, segments => [ { value => 20, color => '#ff0000' }, { value => 10 } ], fractional => 0 );
	is [ $bar->value, row_text( $bar, 0 ) ], [ 30, ( "\x{2588}" x 6 ) . ( "\x{2591}" x 4 ) . '  60%' ], 'segments stack; the value is their sum';
	is shown($bar)->cell( 0, 0 )->[1], $bar->color_attr('#ff0000'),     'the first segment in its color';
	is shown($bar)->cell( 4, 0 )->[1], $bar->color_attr( $bar->color ), 'the second in the bar color';
	$bar->separated(1);
	is row_text( $bar, 0 ), ( "\x{2588}" x 4 ) . "\x{2591}" . ( "\x{2588}" x 2 ) . ( "\x{2591}" x 3 ) . '  60%', 'a cell of track between segments';
	$bar->add_segment( { value => 100 } );
	is [ $bar->value, row_text( $bar, 0 ) ], [ 50, ( "\x{2588}" x 4 ) . "\x{2591}" . ( "\x{2588}" x 2 ) . "\x{2591}" . ( "\x{2588}" x 2 ) . ' 100%' ], 'what goes past max is cut off';
	$bar->value(10);
	is $bar->segments, [], 'a single value drops the segments';
	like dies { $bar->segments( [ { value => -1 } ] ) }, qr/segment value must not be negative/, 'a negative segment dies';
};

subtest 'ranges and invalid values' => sub {
	my ( $bar, $ui ) = bar( min => 10, max => 20, value => 15 );
	is $bar->percent, 50, 'the range has a min';
	$bar->set_range( min => 100, max => 200 );
	is [ $bar->value, $bar->min, $bar->max ], [ 100, 100, 200 ], 'a new range moves the value into it';
	like dies { $bar->value(300) }, qr/value must be in 100\.\.200/, 'a value outside the range dies';
	like dies { Term::Fabulous::Widget::ProgressBar->new( max   => 0 ) },                 qr/min \(0\) must be less than max/,         'an empty range dies';
	like dies { Term::Fabulous::Widget::ProgressBar->new( style => 'x' ) },               qr/style must be one of ascii, block, line/, 'an unknown style';
	like dies { Term::Fabulous::Widget::ProgressBar->new( value => 1, segments => [] ) }, qr/give 'value' or 'segments', not both/,    'value and segments together';

	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::ProgressBar as ProgressBar
ProgressBar "disk" {
	value 300
	max 500
	min 0
	striped #true
	segment value=100 color="#98c379"
	segment value=50
	separated #true
}
KDL
	is [ $built->min, $built->max, $built->striped, $built->separated, scalar $built->segments->@*, $built->value ], [ 0, 500, 1, 1, 2, 150 ], 'KDL: the range first, then the value and the segments';
};

subtest 'animations run on the clock' => sub {
	my $now     = 1000;
	my $root    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $busy    = Term::Fabulous::Widget::ProgressBar->new( indeterminate => 1, preferred_columns => 8 );
	my $striped = Term::Fabulous::Widget::ProgressBar->new( value => 100, striped => 1, animated => 1, preferred_columns => 8, show_value => 0 );
	$root->add_child( $busy, $striped );
	my $ui = Term::Fabulous->new( root => $root, width => 40, height => 10, terminal => Term::Fabulous::Terminal::Memory->new( width => 40, height => 10 ), clock => sub { $now } );

	ok $ui->step >= 1, 'the first frame';
	my $first = row_text( $busy, 0 );
	like $first, qr/\A\x{2591}*\x{2588}{2}\x{2591}*\z/, 'the runner is a quarter of the bar';
	is $ui->step, 0, 'no frame while the clock stands still';
	$now += 0.1;
	is $ui->step,              1,      'a frame when the next one is due';
	isnt row_text( $busy, 0 ), $first, 'the runner moved';
	my $stripes = row_text( $striped, 0 );
	$now += 0.2;
	$ui->step;
	isnt row_text( $striped, 0 ), $stripes, 'the stripes moved';

	$busy->indeterminate(0);
	$striped->animated(0);
	$ui->step;
	$now += 1;
	is $ui->step, 0, 'nothing animates any more, so no frame is due';
};

done_testing;
