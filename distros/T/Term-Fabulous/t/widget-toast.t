use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::Toast;

# A UI on a 60x14 memory terminal with a text at the top.
sub ui () {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child( Term::Fabulous::Widget::Text->new( text => 'Hello' ) );
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 60, height => 14 );
	my $ui       = Term::Fabulous->new( root => $root, width => 60, height => 14, terminal => $terminal );
	$ui->step;
	return ( $ui, $terminal );
}

sub lines ($terminal) {
	return [ map { s/\s+\z//r } $terminal->lines ];
}

subtest 'shown toasts stack in their corner' => sub {
	my ( $ui, $terminal ) = ui();
	my $saved  = Term::Fabulous::Widget::Toast->new( kind    => 'success', title => 'Saved', message => 'Written to disk.' );
	my $second = Term::Fabulous::Widget::Toast->new( message => 'Second' );
	my @closed;
	$_->on( Close => sub ($event) { push @closed, $event->target->title; return } ) foreach $saved, $second;

	ref_is $saved->show($ui), $saved, 'show returns the toast';
	$second->show($ui);
	$ui->step;
	is [ map { $_->is_shown } $saved, $second ], [ 1, 1 ], 'both shown';
	ref_is $saved->stack, $second->stack, 'in one stack';
	my @rows = grep { length } lines($terminal)->@*;
	like $rows[2], qr/\x{2713} Saved\s+\x{2715} \x{2502}\s*\z/, 'the icon, the title and the close mark';
	like $rows[3], qr/Written to disk\./,                       'the message below the title';
	like $rows[6], qr/i Second\s+\x{2715}/,                     'the second toast below, with the info icon';
	ok $rows[2] =~ /\x{2502}\s*\z/ && length( $rows[2] ) == 59, 'a margin of one cell from the right edge';

	$saved->hide;
	$ui->step;
	is [ $saved->is_shown, $second->is_shown, \@closed ], [ 0, 1, ['Saved'] ], 'hide takes one toast away and fires Close';
	$second->expire;
	$ui->step;
	is [ $second->is_shown, \@closed, scalar $ui->root->children->@* ], [ 0, [ 'Saved', '' ], 1 ], 'expire ends the timeout; the empty stack goes';
	is lines($terminal)->[0],                                           'Hello',                   'the screen is clean again';

	$saved->show($ui);
	ok $saved->is_shown, 'a hidden toast can be shown again';
	like dies { $saved->position('top_left') },                          qr/position cannot change while the toast is shown/, 'the position is fixed while shown';
	like dies { Term::Fabulous::Widget::Toast->new->show( $ui->root ) }, qr/show needs the Term::Fabulous object/,            'show needs the UI';
};

subtest 'the close mark, positions and looks' => sub {
	my ( $ui, $terminal ) = ui();
	my $toast = Term::Fabulous::Widget::Toast->new( kind => 'danger', title => 'Lost', important => 1, position => 'bottom_left', timeout => undef )->show($ui);
	$ui->step;
	my $box = $ui->bounding_box($toast);
	is [ $box->{x}, $box->{y} + $box->{height} ], [ 1, 13 ], 'bottom left, a cell from the edges';
	is [ $toast->background_color, $toast->border_color ], [ ( [ 224, 108, 117, 255 ] ) x 2 ], 'an important toast is filled with its color';
	like lines($terminal)->[ $box->{y} + 1 ], qr/\x{2717} Lost\s+\x{2715}/, 'the danger icon';

	$terminal->click( $box->{x} + $box->{width} - 3, $box->{y} + 1 );
	$ui->step;
	ok !$toast->is_shown, 'a click on the close mark hides it';

	$toast->important(0);
	$toast->closable(0);
	$toast->color('#c678dd');
	$toast->icon('*');
	is [ $toast->background_color, $toast->border_color, $toast->kind_color ], [ [ 28, 33, 45, 255 ], [ 198, 120, 221, 255 ], [ 198, 120, 221, 255 ] ], 'back to the panel, a color of your own';
	$toast->background_color('#000000');
	$toast->kind('info');
	is $toast->background_color, [ 0, 0, 0, 255 ], 'a background of your own survives a look change';
	like dies { $toast->kind('fatal') }, qr/kind must be one of danger, info, success, warning, got 'fatal'/, 'an unknown kind dies';
	like dies { Term::Fabulous::Widget::Toast->new( position => 'middle' ) }, qr/position must be one of bottom_center/, 'an unknown position dies';
	like dies { Term::Fabulous::Widget::Toast->new( timeout  => 0 ) },        qr/timeout must be positive/,              'a zero timeout dies';
};

subtest 'an alert in the layout, and children below the message' => sub {
	my $alert = Term::Fabulous::Widget::Toast->new( kind => 'warning', message => 'Unsaved changes.', closable => 0 );
	my $note  = Term::Fabulous::Widget::Text->new( text => 'Press Ctrl+S.' );
	$alert->add_child($note);
	is [ map { ref } $alert->body->children->@* ], [ ('Term::Fabulous::Widget::Text') x 2 ], 'the message, then the child';
	$alert->title('Careful');
	is scalar $alert->body->children->@*, 3, 'a title appears before them';
	is scalar $alert->children->@*,       2, 'no close mark';
	$alert->remove_children_with( sub { $_[0] == $note } );
	is scalar $alert->body->children->@*, 2, 'remove_children_with acts on the children below the message';
	$alert->add_child($note);
	$alert->remove_child( $alert->body->children->@* );
	is [ map { $_->text } $alert->body->children->@* ], [ 'Careful', 'Unsaved changes.' ], 'remove_child removes the children but keeps the title and the message';

	my $built
		= Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Toast as Toast\nToast { kind \"success\"; title \"Done\"; important #true; timeout 2; position \"top_left\"; }" )->build;
	is [ $built->kind, $built->title, $built->important, $built->timeout, $built->position ], [ 'success', 'Done', 1, 2, 'top_left' ], 'the properties of a layout';
	my ( $ui, $terminal ) = ui();
	$ui->root->add_child($built);
	like dies { $built->show($ui) }, qr/a toast that is a child of another widget cannot be shown/, 'a toast in the layout cannot be shown';
};

done_testing;
