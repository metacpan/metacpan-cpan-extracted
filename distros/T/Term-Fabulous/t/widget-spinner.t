use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use InputTest;
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Spinner;

# A spinner on a UI whose clock the test moves.
sub spinner (%args) {
	my $now     = 1000;
	my $spinner = Term::Fabulous::Widget::Spinner->new(%args);
	my $root    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($spinner);
	my $ui = Term::Fabulous->new( root => $root, width => 40, height => 10, terminal => Term::Fabulous::Terminal::Memory->new( width => 40, height => 10 ), clock => sub { $now } );
	$ui->step;
	return ( $spinner, $ui, \$now );
}

subtest 'frames, labels and sizes' => sub {
	my ( $spinner, $ui, $now ) = spinner( style => 'line', label => 'Busy' );
	is [ $spinner->columns, $spinner->rows, row_text( $spinner, 0 ) ], [ 6, 1, '- Busy' ], 'a one-cell frame and the label';
	is [ $spinner->interval, $spinner->frames ], [ 0.13, [ '-', '\\', '|', '/' ] ], 'the style decides the pace and the frames';

	$$now += 0.13;
	$ui->step;
	is row_text( $spinner, 0 ), '\\ Busy', 'the next frame when its time has come';
	$spinner->label_position('left');
	is row_text( $spinner, 0 ), 'Busy \\', 'the label on the left';

	my ( $ring, $ring_ui ) = spinner( style => 'ring', label => 'Loading' );
	is [ $ring->columns, $ring->rows ], [ 11, 3 ], 'three rows, the label beside the middle one';
	is [ map { row_text( $ring, $_ ) } 0 .. 2 ], [ " \x{2588}\x{2588}        ", "\x{2588} \x{2588} Loading", "\x{2588}\x{2588}\x{2588}        " ], 'the ring with its gap';

	my ( $own, $own_ui ) = spinner( frames => [ 'tick', "to\nck" ], interval => 1 );
	is [ $own->columns, $own->rows, $own->frames, $own->interval ], [ 4, 2, [ 'tick', "to\nck" ], 1 ], 'frames of your own, sized by the largest';
	$own->frames(undef);
	$own->interval(undef);
	is [ scalar $own->frames->@*, $own->interval ], [ 10, 0.08 ],                                                          'back to the style';
	is [ Term::Fabulous::Widget::Spinner->styles ], [qw(arc arrow bar bounce box circle dots dots3 line pulse ring wave)], 'the style names';
};

subtest 'running and stopped' => sub {
	my ( $spinner, $ui, $now ) = spinner( style => 'line' );
	is $ui->step, 0, 'no frame while the clock stands still';
	$$now += 0.5;
	is $ui->step, 1, 'a frame when the next one is due';
	$spinner->stop;
	$ui->step;
	is [ $spinner->running, $spinner->frame_index, row_text( $spinner, 0 ) ], [ 0, 0, '-' ], 'stopped at the first frame';
	$$now += 1;
	is $ui->step, 0, 'a stopped spinner asks for no frames';
	$spinner->start;
	$ui->step;
	$$now += 0.13;
	is $ui->step, 1, 'and runs again after start';
};

subtest 'invalid values and layouts' => sub {
	like dies { Term::Fabulous::Widget::Spinner->new( style          => 'twirl' ) }, qr/style must be one of arc, arrow/,           'an unknown style';
	like dies { Term::Fabulous::Widget::Spinner->new( frames         => [] ) },      qr/frames must be an array reference of one/,  'no frames';
	like dies { Term::Fabulous::Widget::Spinner->new( interval       => 0 ) },       qr/interval must be positive/,                 'a zero interval';
	like dies { Term::Fabulous::Widget::Spinner->new( label_position => 'below' ) }, qr/label_position must be one of left, right/, 'an unknown position';

	my $built
		= Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Spinner as Spinner\nSpinner { style \"arc\"; label \"Loading\"; running #false; frames \"a\" \"b\"; interval 0.5; }" )
		->build;
	is [ $built->style, $built->label, $built->running, $built->frames, $built->interval ], [ 'arc', 'Loading', 0, [ 'a', 'b' ], 0.5 ], 'the properties of a layout';
};

done_testing;
