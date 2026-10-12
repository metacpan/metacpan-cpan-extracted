use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed);
use InputTest;
use Term::Fabulous::Layout;
use Term::Fabulous::Render::Attr qw(cell_color_attr);
use Term::Fabulous::Widget::StatusBar;

sub bar (%args) {
	return Term::Fabulous::Widget::StatusBar->new( %args, layout => { sizing => { width => sizing_fixed(30) } } );
}

# The foreground attribute of a cell of the bar's row.
sub fg_at ( $bar, $x ) {
	shown($bar);
	my ( undef, $fgs ) = $bar->cell_row(0);
	return $fgs->[$x];
}

subtest 'a message on the left, parts on the right' => sub {
	my $status = bar( message => 'Ready.', parts => [ 'UTF-8', [ 'Ln 3', 'accent' ] ] );
	my $ui     = layout_ui($status);
	is [ $status->columns, $status->rows ], [ 30, 1 ],                                         'one row, as wide as the layout lets it be';
	is row_text( $status, 0 ),              ' Ready.' . ( ' ' x 11 ) . 'UTF-8  Ln 3 ',         'the message a column in, the parts against the right edge with a gap between them';
	is fg_at( $status, 1 ),                 cell_color_attr( color => $status->text_color ),   'an info message is drawn in text_color';
	is fg_at( $status, 25 ),                cell_color_attr( color => $status->accent_color ), 'a part in the color of its kind';
	is $status->parts,                      [ [ 'UTF-8', 'info' ], [ 'Ln 3', 'accent' ] ],     'a string part reads back as an info part';
};

subtest 'kinds and clearing' => sub {
	my $status = bar();
	my $ui     = layout_ui($status);
	is $status->message( "Saved  notes.txt.\n", 'success' ), 'Saved notes.txt.',                                 'the setter returns the message as shown, on one row';
	is [ $status->message, $status->kind ],                  [ 'Saved notes.txt.', 'success' ],                  'message and kind read back';
	is fg_at( $status, 1 ),                                  cell_color_attr( color => $status->success_color ), 'drawn in the color of its kind';
	$status->kind('danger');
	is fg_at( $status, 1 ), cell_color_attr( color => $status->danger_color ), 'kind recolors the message';
	ref_is $status->clear_message, $status, 'clear_message returns the bar';
	is [ $status->message, $status->kind, row_text( $status, 0 ) ], [ '', 'info', ' ' x 30 ], 'and empties it';
	$status->message( 'Oops', 'warning' );
	is $status->message(''), '',     'an empty message';
	is $status->kind,        'info', 'clears like clear_message';
};

subtest 'a long message is cut before the parts' => sub {
	my $status = bar( message => 'This message is far too long for the bar', parts => ['F1 help'] );
	my $ui     = layout_ui($status);
	is row_text( $status, 0 ), " This message is fa\x{2026}  F1 help ", 'cut with an ellipsis, two columns before the parts';
	$status->parts( ['a part that is much too wide to fit in'] );
	is row_text( $status, 0 ), ' a part that is much too wide ', 'parts wider than the bar push the message out and are cut at the edge';
};

subtest 'parts from a code reference' => sub {
	my $line   = 1;
	my $status = bar( parts => sub { [ "Ln $line", 'dim' ] } );
	my $ui     = layout_ui($status);
	like row_text( $status, 0 ), qr/Ln 1 \z/, 'the parts as the code returns them';
	$line = 42;
	$status->mark_changed;
	like row_text( $status, 0 ), qr/Ln 42 \z/, 'read again when a frame is drawn';
	is [ $status->current_parts ], [ [ 'Ln 42', 'dim' ] ], 'current_parts calls the code';
	$status->parts( sub { [ 'x', 'loud' ] } );
	like dies { $status->current_parts }, qr/the kind of a part must be one of accent, danger, dim, info, success, warning, got 'loud'/, 'a bad part from the code dies when it is drawn';
};

subtest 'timeout' => sub {
	my $status = bar( message => 'Initial', timeout => 5 );
	my $ui     = layout_ui($status);
	$status->expire;
	is $status->message, 'Initial', 'the message given to new has no timeout';
	$status->message('Copied.');
	$status->expire;
	is $status->message, '', 'a message goes away when its timeout runs out';
	$status->timeout(undef);
	$status->message('Stays.');
	$status->expire;
	is $status->message, 'Stays.', 'without a timeout it stays';
	like dies { $status->timeout(0) }, qr/timeout must be positive, or undef for no timeout, got 0/, 'a timeout of 0 dies';
};

subtest 'checks' => sub {
	like dies { bar( kind  => 'error' ) },   qr/kind must be one of danger, info, success, warning, got 'error'/,     'an unknown kind dies';
	like dies { bar( parts => 'Ln 1' ) },    qr/parts must be an array reference or a code reference, got 'Ln 1'/,    'parts must be a list or code';
	like dies { bar( parts => [ ['x'] ] ) }, qr/a part must be a string or \[ text, kind \], got an ARRAY reference/, 'a part needs a text and a kind';
	like dies { bar()->message( 'x', 'dim' ) }, qr/kind must be one of danger, info, success, warning, got 'dim'/, 'dim is a kind of part, not of message';
};

subtest 'the theme colors the bar' => sub {
	my $status = bar();
	my $ui     = layout_ui($status);
	is $status->background_color, $ui->theme->token('surface_low'), 'the background is status_bar.background';
	is $status->dim_color,        $ui->theme->token('placeholder'), 'dim is the placeholder color';
	$status->success_color('#00ff00');
	is $status->success_color, [ 0, 255, 0, 255 ], 'a color of your own';
};

subtest 'a layout file' => sub {
	my $root = Term::Fabulous::Layout->new( string => <<~'KDL' )->build;
		use Term::Fabulous::Widget::StatusBar as StatusBar
		StatusBar "status" {
			message "Ready."
			kind "warning"
			timeout 3
		}
		KDL
	is [ $root->message, $root->kind, $root->timeout ], [ 'Ready.', 'warning', 3 ], 'message, kind and timeout';
};

done_testing;
