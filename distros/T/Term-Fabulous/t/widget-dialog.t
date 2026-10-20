use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed sizing_grow);
use InputTest;
use Scalar::Util qw(refaddr weaken);
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Dialog;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Term::Fabulous::Widget::VirtualList;

sub button () {
	return Term::Fabulous::Widget::Button->new( background_color => [ 2, 2, 2, 255 ], layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(1) } } );
}

my $root   = Term::Fabulous::Widget::Box->new( background_color => [ 1, 1, 1, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $behind = button();
$root->add_child($behind);
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 9 );
my $ui       = Term::Fabulous->new( width => 30, height => 9, root => $root, terminal => $terminal );

my $dialog = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(12) } } );
my @inside = ( button(), button() );
$dialog->add_child(@inside);
my @closes;
$dialog->on( Close => sub { push @closes, $_[0]->target; return } );

sub press_key ($name) {
	$terminal->press_key($name);
	$ui->step;
	return;
}

subtest 'open puts the dialog over the root and focuses inside' => sub {
	$ui->interaction->set_focused_widget($behind);
	$dialog->open($ui);
	ok $dialog->is_open, 'open';
	ref_is $dialog->parent,                      $dialog->backdrop, 'the dialog sits in its backdrop';
	ref_is $dialog->backdrop->parent,            $root,             'which is a child of the root';
	ref_is $ui->interaction->get_focused_widget, $inside[0],        'the first focusable widget inside has the focus';
	ref_is $dialog->open($ui),                   $dialog,           'opening again is a no-op that returns the dialog';
};

subtest 'Tab stays inside the dialog' => sub {
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $inside[1], 'Tab moves to the next widget inside';
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $inside[0], 'and wraps around inside the dialog';
};

subtest 'the backdrop takes clicks outside the dialog' => sub {
	$ui->step;
	my @mouse_targets;
	$root->on( Mouse => sub { push @mouse_targets, $_[0]->target; return } );
	$terminal->mouse( key => TB_KEY_MOUSE_LEFT, x => 1, y => 0 );
	$ui->step;
	ref_is $mouse_targets[0],                    $dialog->backdrop, 'the button behind the dialog does not get the click';
	ref_is $ui->interaction->get_focused_widget, $dialog->backdrop, 'the backdrop takes the focus';
	is $dialog->backdrop->layout->{sizing}, { width => sizing_grow(), height => sizing_grow() }, 'the backdrop fills the screen';

	press_key('BackTab');
	ref_is $ui->interaction->get_focused_widget, $inside[-1], 'Shift+Tab from the backdrop goes to the last widget';
	$ui->interaction->set_focused_widget( $dialog->backdrop );
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $inside[0], 'Tab to the first';
};

subtest 'keys stay inside the open dialog' => sub {
	my @root_keys;
	$root->on( KeyPress => sub { push @root_keys, $_[0]->key_name; return } );
	press( $inside[0],        'd' );
	press( $dialog->backdrop, 'q' );
	is \@root_keys, [], 'the key bindings behind the dialog do not see them';
	ok $dialog->is_open, 'and the dialog stays open';
};

subtest 'Escape closes and the focus goes back' => sub {
	press( $inside[0], 'Escape' );
	ok !$dialog->is_open, 'closed';
	is $dialog->parent,                                                                            undef, 'the dialog has no parent any more';
	is scalar( grep { $_->isa('Term::Fabulous::Widget::Dialog::Backdrop') } $root->children->@* ), 0,     'the backdrop is gone from the root';
	ref_is $ui->interaction->get_focused_widget, $behind, 'the focus is back where it was';
	is scalar @closes, 1, 'Close fired once';
	ref_is $closes[0],     $dialog, 'on the dialog';
	ref_is $dialog->close, $dialog, 'closing again does nothing';
	is scalar @closes, 1, 'and fires nothing';
};

subtest 'a dialog opens again' => sub {
	$dialog->open($ui);
	ok $dialog->is_open, 'open a second time';
	ref_is $ui->interaction->get_focused_widget, $inside[0], 'with the focus inside';
	$dialog->close_on_escape(0);
	press( $inside[0], 'Escape' );
	ok $dialog->is_open, 'Escape is ignored when close_on_escape is off';
	$dialog->close;
	is scalar @closes, 2, 'close from code fires Close too';
};

subtest 'the focus stays inside when the focused widget loses it' => sub {
	my $field  = Term::Fabulous::Widget::TextField->new;
	my $other  = button();
	my $editor = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(12) } } );
	$editor->add_child( $field, $other );
	$editor->open($ui);
	ref_is $ui->interaction->get_focused_widget, $field, 'the field has the focus';

	$field->disabled(1);
	ref_is $ui->interaction->get_focused_widget, $editor->backdrop, 'disabling it hands the focus to the backdrop';
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $other, 'Tab stays inside the dialog';

	$editor->remove_children_with( sub ($child) { refaddr($child) == refaddr($other) } );
	ref_is $ui->interaction->get_focused_widget, $editor->backdrop, 'removing the focused widget does too';
	$ui->interaction->set_focused_widget(undef);
	ref_is $ui->interaction->get_focused_widget, $editor->backdrop, 'and focusing nothing';

	press( $editor->backdrop, 'Escape' );
	ok !$editor->is_open, 'Escape still closes it';
	ref_is $ui->interaction->get_focused_widget, $behind, 'and the focus goes back behind it';
};

subtest 'Tab reaches the items of a VirtualList inside the dialog' => sub {
	my @items = map { button() } 0 .. 2;
	my $list  = Term::Fabulous::Widget::VirtualList->new(
		id     => 'dialog-list',
		count  => scalar @items,
		build  => sub ($index) { return $items[$index] },
		layout => { sizing => { width => sizing_fixed(6), height => sizing_fixed(3) } },
	);
	my $first   = button();
	my $chooser = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(12) } } );
	$chooser->add_child( $first, $list );
	$chooser->open($ui);
	$ui->step;
	ref_is $ui->interaction->get_focused_widget, $first, 'the button before the list has the focus';
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $items[0], 'Tab moves to the first item of the list';
	press_key('BackTab');
	press_key('BackTab');
	ref_is $ui->interaction->get_focused_widget, $items[-1], 'Shift+Tab wraps around to the last item';
	$chooser->close;
};

subtest 'a dropdown list opens over its dialog' => sub {
	my $dropdown = Term::Fabulous::Widget::Dropdown->new( options => [qw(Red Green Blue)] );
	my $picker   = Term::Fabulous::Widget::Dialog->new( z_index => 5000, layout => { sizing => { width => sizing_fixed(16) } } );
	$picker->add_child($dropdown);
	$picker->open($ui);
	$dropdown->open;
	$ui->step;
	my ($list) = @{ $dropdown->children };
	my ( $x, $y ) = $list->content_origin;
	$terminal->click( $x, $y + 1 );
	$ui->step;
	is [ $dropdown->value, $dropdown->is_open ], [ 'Green', 0 ], 'a click on a row of the list chooses it, whatever the z_index of the dialog';
	$picker->close;
};

subtest 'a dialog opened from inside another one' => sub {
	$ui->interaction->set_focused_widget($behind);
	my $outer        = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(16) } } );
	my @outer_inside = ( button(), button() );
	$outer->add_child(@outer_inside);
	$outer->open($ui);
	$ui->step;
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $outer_inside[1], 'the second widget of the outer dialog has the focus';

	my $inner        = Term::Fabulous::Widget::Dialog->new( z_index => $outer->z_index + 1, layout => { sizing => { width => sizing_fixed(10) } } );
	my $inner_inside = button();
	$inner->add_child($inner_inside);
	$inner->open($ui);
	$ui->step;
	ref_is $ui->interaction->get_focused_widget, $inner_inside, 'the inner dialog takes the focus';
	press_key('Tab');
	ref_is $ui->interaction->get_focused_widget, $inner_inside, 'Tab stays inside the inner dialog';

	press_key('Escape');
	ok !$inner->is_open, 'Escape closes the inner dialog';
	ok $outer->is_open,  'but not the outer one';
	ref_is $ui->interaction->get_focused_widget, $outer_inside[1], 'the focus goes back into the outer dialog';

	press_key('Escape');
	ok !$outer->is_open, 'Escape again closes the outer dialog';
	ref_is $ui->interaction->get_focused_widget, $behind, 'and the focus goes back behind both';
};

subtest 'close after the program removed the dialog' => sub {
	my $box       = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $screen_ui = Term::Fabulous->new( width => 30, height => 9, root => $box );
	my $removed   = Term::Fabulous::Widget::Dialog->new;
	$removed->add_child( button() );
	my $closed = 0;
	$removed->on( Close => sub { $closed++; return } );
	$removed->open($screen_ui);

	$box->clear_children;
	ok $removed->is_open,         'the dialog counts as open until it is closed';
	ok lives { $removed->close }, 'close does not die';
	is [ $removed->is_open, $closed, $removed->parent ], [ 0, 1, undef ], 'it is closed, Close fired, it can be opened again';
	ok lives { $removed->open($screen_ui)->close }, 'and it does';
};

subtest 'an open dialog does not keep a dropped UI alive' => sub {
	my $box       = Term::Fabulous::Widget::Box->new;
	my $screen_ui = Term::Fabulous->new( width => 30, height => 9, root => $box );
	my $open      = Term::Fabulous::Widget::Dialog->new;
	$open->open($screen_ui);
	weaken( my $weak_dialog = $open );
	weaken( my $weak_ui     = $screen_ui );
	undef $_ foreach $open, $screen_ui, $box;
	is [ $weak_dialog, $weak_ui ], [ undef, undef ], 'both are freed';
};

subtest 'defaults and errors' => sub {
	is $dialog->bordered,          { top  => 1, right => 1, bottom => 1, left   => 1 }, 'a border by default, from dialog.border.enabled';
	is $dialog->layout->{padding}, { left => 1, right => 1, top    => 1, bottom => 1 }, 'padding by default';
	is $dialog->layout->{sizing}{width}, sizing_fixed(12), 'the given layout keys win';
	my $fresh = Term::Fabulous::Widget::Dialog->new;
	is [ $fresh->backdrop_color, $fresh->z_index, $fresh->close_on_escape ], [ [ 0, 0, 0, 128 ], 1000, 1 ], 'the dialog parameters';
	like dies { $dialog->open('nope') },                                           qr/open needs the Term::Fabulous object/,                        'open wants the UI';
	like dies { Term::Fabulous::Widget::Dialog->new( z_index => 'top' ) },         qr/z_index must be an integer/,                                  'z_index is checked';
	like dies { Term::Fabulous::Widget::Dialog->new( z_index => 40000 ) },         qr/z_index must be an integer from -32768 to 32767, got 40000/,  'z_index stays in the range Clay has';
	like dies { $fresh->z_index(-40000) },                                         qr/z_index must be an integer from -32768 to 32767, got -40000/, 'also when it is set later';
	like dies { Term::Fabulous::Widget::Dialog->new( backdrop_color => 'nope' ) }, qr/\ATerm::Fabulous::Widget::Dialog: backdrop_color must be a color, got 'nope'/, 'backdrop_color is checked';

	my $child  = Term::Fabulous::Widget::Dialog->new;
	my $holder = Term::Fabulous::Widget::Box->new;
	$holder->add_child($child);
	like dies { $child->open($ui) }, qr/child of another widget cannot open/, 'a dialog inside the tree cannot open';
};

# A dialog with a title, a text and two buttons, open on the screen; its
# answers as [ button, values, dismissed ] and the events in order.
sub answering_dialog (%params) {
	my $asking = Term::Fabulous::Widget::Dialog->new(
		title   => 'Export',
		buttons => [ { id => 'export', label => 'Export', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
		layout  => { sizing => { width => sizing_fixed(24) } },
		%params,
	);
	$asking->add_child( Term::Fabulous::Widget::Text->new( text => 'All rows' ) );
	my ( @answers, @events );
	$asking->on( Close => sub { push @events, 'Close'; return } );
	$asking->on( Answer => sub ($event) { push @events, 'Answer'; push @answers, [ $event->button, $event->values, $event->dismissed ]; return } );
	$ui->interaction->set_focused_widget($behind);
	$asking->open($ui);
	$ui->step;
	return ( $asking, \@answers, \@events );
}

sub screen_lines () {
	return [ map { s/\s+\z//r } $terminal->lines ];
}

subtest 'title, content, notice line and buttons in their places' => sub {
	my ($asking) = answering_dialog();
	is [ map { ref } @{ $asking->children } ],                     [ ('Term::Fabulous::Widget::Text') x 2, 'Term::Fabulous::Widget::Box' ], 'the title, the content and the button row';
	is [ map { $asking->button($_)->classes } qw(export cancel) ], [ ['primary'], [] ],                                                     'a primary button has the class primary';
	is [ map { $asking->is_primary($_) } qw(export cancel) ],      [ 1, 0 ],                                                                'is_primary';
	is [ $asking->button_ids ],                                    [qw(export cancel)],                                                     'the buttons in order';
	is $asking->default_button,                                    'export',                                                                'the default button is the first primary one';
	like dies { $asking->button('nope') }, qr/\ATerm::Fabulous::Widget::Dialog: the dialog has no button with the id 'nope'/, 'an unknown button dies';
	my $lines = screen_lines();
	like $lines->[1], qr/Export/,   'the title is the first row inside the border';
	like $lines->[3], qr/All rows/, 'then the content';

	$asking->notice( 'Nothing to export: the [bold]table[/] is empty.', 'error' );
	$ui->step;
	is $asking->children->[-2]->children->[0]->text,       'Nothing to export: the table is empty.',                                                        'the notice line comes above the buttons';
	is [ $asking->notice, $asking->notice_text ],          [ 'Nothing to export: the [bold]table[/] is empty.', 'Nothing to export: the table is empty.' ], 'notice and notice_text';
	is $asking->children->[-2]->children->[0]->text_color, $asking->family_look( input => 'text', 'invalid' ),                                              'an error in the color of an invalid input';
	$asking->notice('Two rows are hidden.');
	is $asking->children->[-2]->children->[0]->text_color, Term::Fabulous::Widget::Text->new->text_color, 'an info notice in the text color';
	$asking->notice('');
	is [ scalar @{ $asking->children }, $asking->notice, $asking->notice_text ], [ 3, undef, undef ], 'an empty notice takes the line away';
	like dies { $asking->notice( 'x', 'loud' ) }, qr/the kind of a notice must be one of error, info, got 'loud'/, 'an unknown kind dies';
	$asking->title('');
	is scalar @{ $asking->children }, 2, 'an empty title takes the title away';
	$asking->title('Export again');
	is $asking->children->[0]->text, 'Export again', 'a new title comes back first';
	$asking->close;
};

subtest 'the notice line keeps its place when asked' => sub {
	my %rows;
	foreach my $notice_line (qw(shown kept row)) {
		my ($asking) = answering_dialog( notice_line => $notice_line );
		$rows{$notice_line} = $ui->bounding_box($asking)->{height};
		$asking->close;
	}
	is [ @rows{qw(kept row)} ], [ $rows{shown} + 1, $rows{shown} + 2 ], 'kept adds the gap above the line, row also a row';
	my ($asking) = answering_dialog( notice_line => 'row' );
	my $height = $ui->bounding_box($asking)->{height};
	$asking->notice('Saved.');
	$ui->step;
	is $ui->bounding_box($asking)->{height}, $height, 'with row a short notice does not change the height';
	$asking->close;
	like dies { Term::Fabulous::Widget::Dialog->new( notice_line => 'always' ) }, qr/notice_line must be one of kept, row, shown, got 'always'/, 'an unknown notice_line dies';
};

subtest 'a button answers, Escape and close dismiss' => sub {
	my ( $asking, $answers, $events ) = answering_dialog();
	press( $asking->button('export'), 'Enter' );
	ok !$asking->is_open, 'pressing a button closes the dialog';
	is $answers, [ [ 'export', {}, 0 ] ], 'and answers with its id';
	is $events,  [qw(Close Answer)],      'after Close';
	ref_is $ui->interaction->get_focused_widget, $behind, 'with the focus back';

	( $asking, $answers ) = answering_dialog();
	press( $asking->button('export'), 'Escape' );
	is $answers, [ [ 'cancel', {}, 1 ] ], 'Escape answers cancel, dismissed';

	( $asking, $answers ) = answering_dialog();
	$asking->answer( export => path => '/tmp/x.csv' );
	is $answers, [ [ 'export', { path => '/tmp/x.csv' }, 0 ] ], 'answer carries the values given';
	like dies { $asking->answer('export') }, qr/answer needs an open dialog/, 'a closed dialog cannot answer';
	$asking->open($ui);
	like dies { $asking->answer('nope') }, qr/the dialog has no button with the id 'nope'/, 'nor with an id that is no button';
	$asking->close;
	is $answers->[-1], [ 'cancel', {}, 1 ], 'close dismisses';

	my $plain = Term::Fabulous::Widget::Dialog->new;
	my @plain;
	$plain->on( Answer => sub ($event) { push @plain, [ $event->button, $event->dismissed ]; return } );
	$plain->open($ui);
	$plain->answer('done');
	is \@plain, [ [ 'done', 0 ] ], 'a dialog without buttons answers with any id';
};

subtest 'a dialog on the right' => sub {
	my ($asking) = answering_dialog( placement => 'right' );
	my $box = $ui->bounding_box($asking);
	is $box->{x} + $box->{width},    29,                   'it ends a column before the right edge';
	is $asking->floating->{z_index}, $asking->z_index + 1, 'over its backdrop';
	$asking->z_index(50);
	is $asking->floating->{z_index}, 51, 'also when the z_index changes';
	$asking->placement('center');
	is $asking->floating, undef, 'back in the middle it does not float';
	$asking->close;
	like dies { Term::Fabulous::Widget::Dialog->new( placement => 'left' ) }, qr/placement must be one of center, right, got 'left'/, 'an unknown placement dies';
};

subtest 'KDL properties' => sub {
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Dialog as Dialog
Dialog "about" {
	backdrop_color "#000000"
	z_index 7
	close_on_escape #false
	title "About"
	notice_line row
	placement right
}
KDL
	is [ $built->backdrop_color, $built->z_index, $built->close_on_escape ], [ [ 0, 0, 0, 255 ], 7, 0 ], 'backdrop_color, z_index and close_on_escape';
	is [ $built->title, $built->notice_line, $built->placement ], [ 'About', 'row', 'right' ], 'title, notice_line and placement';
};

done_testing;
