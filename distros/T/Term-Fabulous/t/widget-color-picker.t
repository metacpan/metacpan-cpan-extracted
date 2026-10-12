use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow);
use List::Util qw(first);
use Term::Fabulous;
use Term::Fabulous::Color;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ColorPicker;
use Term::Fabulous::Widget::Prompt;

my $Picker   = 'Term::Fabulous::Widget::ColorPicker';
my @SWATCHES = ( [ accent => 'Accent', '#61afef' ], [ danger => 'Danger', '#e06c75' ], [ none => 'none (no color)' ] );

my $root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 80, height => 24 );
my $ui       = Term::Fabulous->new( width => 80, height => 24, root => $root, terminal => $terminal );

sub keys_ (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub type_ ($text) {
	$terminal->type_text($text);
	$ui->step;
	return;
}

sub focus ($widget) {
	$ui->interaction->set_focused_widget($widget);
	$ui->step;
	return;
}

# A picker on the screen, alone.
sub shown (%params) {
	my $picker = $Picker->new(%params);
	$root->clear_children;
	$root->add_child($picker);
	$ui->step;
	return $picker;
}

sub part ( $picker, $class ) {
	return first { $_->isa("Term::Fabulous::Widget::$class") } $picker->descendants;
}

sub sliders_of ($picker) {
	return grep { $_->isa('Term::Fabulous::Widget::Slider') } $picker->descendants;
}

sub levels_of ($picker) {
	return [ map { $_->value } sliders_of($picker) ];
}

# Records the Change and Submit events that reach the root, with their
# targets.
sub recorded () {
	my @events;
	$root->on( $_ => sub ($event) { push @events, [ $event->name, $event->value, $event->target ]; return } ) foreach qw(Change Submit);
	return \@events;
}

subtest 'the value, the field and the sliders' => sub {
	my $picker = shown( value => '#3b82f6' );
	is $picker->value,                      '#3b82f6',             'value';
	is $picker->rgba,                       [ 59, 130, 246, 255 ], 'rgba';
	is part( $picker, 'TextField' )->value, '#3b82f6',             'the field shows it';
	is levels_of($picker),                  [ 59, 130, 246, 255 ], 'the RGB sliders and the alpha slider show it';
	like dies { $Picker->new( value => 'accent' ) }, qr/value must be a color/, 'a value that is no swatch and no color dies';
};

subtest 'switching RGB/HSL keeps the value' => sub {
	my $picker = shown( value => '#3b82f6' );
	my $events = recorded();
	part( $picker, 'SegmentedControl' )->choose(1);
	is $picker->sliders,   'hsl',                                                      'the switch chose HSL';
	is $picker->value,     '#3b82f6',                                                  'the value stays';
	is levels_of($picker), [ Term::Fabulous::Color->rgb_to_hsl( 59, 130, 246 ), 255 ], 'the sliders read H, S and L from the color';
	is( ( sliders_of($picker) )[0]->max, 359, 'H runs to 359' );
	part( $picker, 'SegmentedControl' )->choose(0);
	is levels_of($picker), [ 59, 130, 246, 255 ], 'back to RGB';
	is $events,            [],                    'switching fires no Change';
};

subtest 'in HSL mode a slider writes hex, and S to 0 and back keeps H' => sub {
	my $picker = shown( value => '#3b82f6', sliders => 'hsl' );
	my ( $hue, $saturation, $lightness ) = sliders_of($picker);
	my $hue_before = $hue->value;
	focus($saturation);
	keys_('Home');
	is $saturation->value, 0, 'S at 0';
	like $picker->value, qr/\A#([0-9a-f]{2})\1\1\z/, 'the value is a gray in hex';
	is $hue->value, $hue_before, 'H stays on its slider';
	keys_('End');
	is $picker->value, sprintf( '#%02x%02x%02x', Term::Fabulous::Color->hsl_to_rgb( $hue_before, 100, $lightness->value ) ), 'S back up: the hue comes back';
};

subtest 'alpha => 0 rejects a translucent color and hides the alpha slider' => sub {
	my $picker = shown( value => '#3b82f6', alpha => 0 );
	my $events = recorded();
	is scalar( () = sliders_of($picker) ), 3, 'no alpha slider';
	my $field = part( $picker, 'TextField' );
	focus($field);
	$field->value('');
	type_('rgba(255, 0, 0, 0.5)');
	is $picker->error,    'Please enter a color without transparency.', 'the field rejects it';
	is $picker->is_valid, 0,                                            'the picker is not valid';
	is $picker->value,    '#3b82f6',                                    'the value stays';
	is $events,           [],                                           'no Change';
	like dies { $Picker->new( value => '#ff000080', alpha => 0 ) }, qr/opaque/, 'a translucent value dies';
};

subtest 'swatches' => sub {
	my $picker = shown( value => '#3b82f6', swatches => [@SWATCHES] );
	my $events = recorded();
	my $list   = part( $picker, 'Table' );
	is [ $list->selected_ids ], [], 'a color that is no swatch selects none';
	focus($list);
	keys_('Down');
	is $picker->value,                      'danger',               'the cursor on a swatch sets the value';
	is levels_of($picker),                  [ 224, 108, 117, 255 ], 'a swatch with a color re-syncs the sliders';
	is part( $picker, 'TextField' )->value, '',                     'and empties the field';
	keys_('Down');
	is $picker->value,                            'none',                                           'a swatch with no color sets the value';
	is $picker->rgba,                             undef,                                            'and has no color';
	is [ map { [ $_->[0], $_->[1] ] } @$events ], [ [ Change => 'danger' ], [ Change => 'none' ] ], 'a Change for each';
	keys_('Enter');
	is $events->[-1][0], 'Submit', 'Enter on a swatch fires Submit';
	is $events->[-1][1], 'none',   'with the value';
};

subtest 'Enter on a swatch that is not chosen chooses it' => sub {
	my $picker = shown( value => 'accent', swatches => [@SWATCHES] );
	my $events = recorded();
	focus( part( $picker, 'TextField' ) );
	type_('#102030');
	focus( part( $picker, 'Table' ) );
	keys_('Enter');
	is $picker->value,                                      'accent',                                           'the swatch under the cursor is the value';
	is [ map { [ $_->[0], $_->[1] ] } @$events[ -2, -1 ] ], [ [ Change => 'accent' ], [ Submit => 'accent' ] ], 'a Change, then the Submit with it';
};

subtest 'typing clears the list selection' => sub {
	my $picker = shown( value => 'accent', swatches => [@SWATCHES] );
	my $list   = part( $picker, 'Table' );
	is [ $list->selected_ids ], ['accent'], 'the swatch is selected';
	my $field = part( $picker, 'TextField' );
	focus($field);
	type_('#102030');
	is $picker->value,          '#102030',           'a typed color is the value';
	is [ $list->selected_ids ], [],                  'the list has no selection';
	is levels_of($picker),      [ 16, 32, 48, 255 ], 'the sliders follow';
};

subtest 'a listener on the picker sees only its Change' => sub {
	my $picker = shown( value => '#000000' );
	my $events = recorded();
	my ($red)  = sliders_of($picker);
	focus($red);
	keys_('Right');
	part( $picker, 'SegmentedControl' )->choose(1);
	focus( part( $picker, 'TextField' ) );
	part( $picker, 'TextField' )->value('');
	type_('red');
	is [ map { [ $_->[0], $_->[1] ] } @$events ], [ [ Change => '#010000' ], [ Change => 'red' ] ], 'the picker\'s Change for the slider and for the typed color, none for the switch';
	ok( ( !grep { $_->[2] != $picker } @$events ), 'every one from the picker' );
};

subtest 'Enter in the field fires Submit' => sub {
	my $picker = shown( value => '#3b82f6' );
	my $events = recorded();
	focus( part( $picker, 'TextField' ) );
	keys_('Enter');
	is [ map { [ $_->[0], $_->[1] ] } @$events ], [ [ Submit => '#3b82f6' ] ], 'one Submit with the value';
	ref_is $events->[0][2], $picker, 'from the picker';
};

subtest 'value() re-syncs the field, the sliders and the list' => sub {
	my $picker = shown( value => '#3b82f6', swatches => [@SWATCHES] );
	my $events = recorded();
	my $list   = part( $picker, 'Table' );
	$picker->value('danger');
	is [ $list->selected_ids ], ['danger'],             'a swatch is selected';
	is levels_of($picker),      [ 224, 108, 117, 255 ], 'its color is on the sliders';
	$picker->value('rgb(1, 2, 3)');
	is part( $picker, 'TextField' )->value, 'rgb(1, 2, 3)',   'a color is in the field as given';
	is [ $list->selected_ids ],             [],               'and no swatch is selected';
	is levels_of($picker),                  [ 1, 2, 3, 255 ], 'the sliders follow';
	is $events,                             [],               'setting fires no Change';
};

subtest 'as a Prompt field an invalid text blocks OK' => sub {
	foreach my $case ( [ 'without swatches' => () ], [ 'with swatches' => ( swatches => [@SWATCHES] ) ] ) {
		my ( $name, @params ) = @$case;
		my $picker = $Picker->new( value => '#3b82f6', @params );
		my $prompt = Term::Fabulous::Widget::Prompt->new( title => 'Color', fields => [ { name => 'color', label => 'Color', input => $picker } ] );
		my @answers;
		$prompt->on( Answer => sub ($event) { push @answers, $event->values; return } );
		$prompt->open($ui);
		my $field = part( $picker, 'TextField' );
		$field->value('');
		focus($field);
		type_('no color');
		$prompt->answer('ok');
		ok $prompt->is_open, "$name: the prompt stays open";
		like $prompt->error, qr/\AColor: Please enter a color/, "$name: the error line names the field";
		focus( $prompt->button('ok') );
		$prompt->answer('ok');
		ref_is $ui->interaction->get_focused_widget, $field, "$name: the field gets the focus";
		$field->value('');
		focus($field);
		type_('#00ff00');
		$prompt->answer('ok');
		is \@answers, [ { color => '#00ff00' } ], "$name: a valid color answers";
	}
};

subtest 'KDL' => sub {
	my $picker = Term::Fabulous::Layout->new( string => <<~'KDL' )->build;
		use Term::Fabulous::Widget::ColorPicker as ColorPicker
		ColorPicker "picker" {
			alpha #false
			sliders "hsl"
			value "#ff0000"
			list_rows 5
		}
		KDL
	is [ $picker->value, $picker->alpha, $picker->sliders, $picker->list_rows ], [ '#ff0000', 0, 'hsl', 5 ], 'value, alpha, sliders and list_rows';
	is levels_of($picker), [ 0, 100, 50 ], 'the HSL sliders without alpha';
};

done_testing;
