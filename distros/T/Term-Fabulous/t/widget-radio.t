use v5.32;
use warnings;
use utf8;

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::UI::Events::OnRelease;
use InputTest;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::RadioButton;
use Term::Fabulous::Widget::RadioGroup;

sub radio_group {
	my (%options) = @_;

	my $group   = Term::Fabulous::Widget::RadioGroup->new(%options);
	my @buttons = map { Term::Fabulous::Widget::RadioButton->new( label => $_->[0], value => $_->[1] ) } [ Small => 's' ], [ Medium => 'm' ], [ Large => 'l' ];
	my $nested  = Term::Fabulous::Widget::Box->new;
	$group->add_child( @buttons[ 0, 1 ], $nested );
	$nested->add_child( $buttons[2] );
	my $ui = layout_ui($group);
	return ( $group, \@buttons, $ui );
}

subtest 'the group selects one button' => sub {
	my ( $group, $buttons, $ui ) = radio_group( value => 'm' );
	is [ map { $_->label } $group->buttons ],   [qw(Small Medium Large)],                          'buttons in nested boxes belong to the group';
	is [ map { row_text( $_, 0 ) } @$buttons ], [ '( ) Small', "(\x{2022}) Medium", '( ) Large' ], 'the selected button shows its mark';
	ok !$buttons->[0]->can_focus, 'buttons do not take the focus';
	my ($unfocusable) = radio_group( can_focus => 0 );
	ok !$unfocusable->can_focus, 'can_focus => 0 is kept';
	$unfocusable->disabled(1);
	$unfocusable->disabled(0);
	ok !$unfocusable->can_focus, 'and survives a disable/enable cycle';
	$unfocusable->disabled(1);
	$unfocusable->can_focus(1);
	ok !$unfocusable->can_focus, 'can_focus(1) while disabled waits';
	$unfocusable->disabled(0);
	ok $unfocusable->can_focus, 'until the group is enabled';

	$group->value('l');
	is [ map { $_->is_selected } @$buttons ], [ 0, 0, 1 ], 'setting the value selects another button';
	is( Term::Fabulous::Widget::RadioButton->new( label => 'Same' )->value, 'Same', 'the value defaults to the label' );
};

subtest 'keys and clicks' => sub {
	my ( $group, $buttons, $ui ) = radio_group();
	my @changes;
	$group->on( Change => sub { push @changes, $_[0]->value; return } );

	press( $group, 'Space' );
	press( $group, 'Down' );
	press( $group, 'Down' );
	press( $group, 'Down' );
	press( $group, 'End' );
	is \@changes, [qw(s m l s l)], 'Space selects the first button, arrows step and wrap, End jumps';

	$buttons->[1]->disabled(1);
	press( $group, 'Up' );
	is $group->value, 's', 'arrows skip disabled buttons';

	$buttons->[2]->fire_event( Clay::UI::Events::OnRelease->new );
	is $group->value, 'l', 'a click selects a button';
	$buttons->[1]->fire_event( Clay::UI::Events::OnRelease->new );
	is $group->value, 'l', 'a click on a disabled button does nothing';
};

subtest 'focus is shown on the cursor button' => sub {
	my ( $group, $buttons, $ui ) = radio_group( value => 'm' );
	my $focus = $buttons->[1]->color_attr( $buttons->[1]->focus_background_color );
	$ui->interaction->set_focused_widget($group);
	is [ map { shown($_)->cell( 0, 0 )->[2] } @$buttons ], [ undef, $focus, undef ], 'the selected button shows the focus';

	$group->disabled(1);
	ok !$group->is_focused,        'disabling the group removes its focus';
	ok !$buttons->[0]->is_enabled, 'its buttons are disabled with it';
};

subtest 'the focus follows the cursor when its button is disabled' => sub {
	my ( $group, $buttons, $ui ) = radio_group( value => 'm' );
	my $focus = $buttons->[0]->color_attr( $buttons->[0]->focus_background_color );
	$ui->interaction->set_focused_widget($group);
	shown($group);
	$buttons->[1]->disabled(1);
	ref_is $group->cursor_button, $buttons->[0], 'the cursor moves to the first enabled button';
	is [ map { shown($_)->cell( 0, 0 )->[2] } @$buttons ], [ $focus, undef, undef ], 'and the next frame shows it there';
};

subtest 'a button outside a group' => sub {
	my $button = Term::Fabulous::Widget::RadioButton->new( label => 'Alone' );
	my $ui     = layout_ui($button);
	like dies { $button->fire_event( Clay::UI::Events::OnRelease->new ) }, qr/must be inside a Term::Fabulous::Widget::RadioGroup/, 'clicking it dies';
};

done_testing;
