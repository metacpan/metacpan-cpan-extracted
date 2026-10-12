use v5.32;
use warnings;
use utf8;

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use InputTest;
use Term::Fabulous::Termbox qw(TB_MOD_MOTION TB_MOD_SHIFT TB_REVERSE);
use Term::Fabulous::Editor;
use Term::Fabulous::Layout;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::TextField;

sub text_field {
	my (%options) = @_;

	my $field = Term::Fabulous::Widget::TextField->new( preferred_columns => 8, %options );
	my $ui    = layout_ui($field);
	return ( $field, $ui );
}

sub events {
	my ( $field, $name ) = @_;
	my @values;
	$field->on( $name => sub { push @values, $_[0]->value; return } );
	return \@values;
}

subtest 'size and value' => sub {
	my ( $field, $ui ) = text_field( value => 'hi' );
	is [ $field->columns, $field->rows ], [ 8, 1 ],   'preferred_columns and one row without a layout size';
	is row_text( $field, 0 ),             'hi      ', 'the value is painted';
	$field->value("a\nb");
	is $field->value, 'a b', 'line breaks become spaces';
	like dies { Term::Fabulous::Widget::TextField->new( mask => '**' ) }, qr/mask must be a single character/,                                                       'an invalid mask dies';
	like dies { $field->max_length(1) },                                  qr/^Term::Fabulous::Widget::TextField: the text has 3 characters, more than max_length 1/, 'editor errors name the widget';
	is( Term::Fabulous::Widget::TextField->new( read_only => 'yes', disabled => 'no' )->read_only, 1, 'read_only is stored as 1 or 0' );
	like dies { Term::Fabulous::Widget::TextField->new( preferred_columns => 0 ) }, qr/positive integer/, 'an invalid width dies';
};

subtest 'edits through the editor scroll the view' => sub {
	my ( $field, $ui ) = text_field( value => 'abcdefghijkl' );
	is row_text( $field, 0 ), 'fghijkl ', 'the view shows the cell after the text, where the cursor is';
	$field->editor->move_to( 0, 0 );
	$field->mark_changed;
	is row_text( $field, 0 ), 'abcdefgh', 'the next frame scrolls back to the cursor';
};

subtest 'typing fires Change, Enter fires Submit' => sub {
	my ( $field, $ui ) = text_field();
	my $changes = events( $field, 'Change' );
	my $submits = events( $field, 'Submit' );
	type_text( $field, 'abc' );
	press( $field, 'Backspace' );
	press( $field, 'Enter' );
	is $changes, [ 'a', 'ab', 'abc', 'ab' ], 'one Change per edit';
	is $submits, ['ab'],                     'Submit with the text';

	$field->value('quiet');
	is scalar @$changes, 4, 'setting the value fires nothing';
};

subtest 'cursor, selection and focus painting' => sub {
	my ( $field, $ui ) = text_field( value => 'abc' );
	is shown($field)->cell( 3, 0 ), undef, 'no cursor without focus';

	$ui->interaction->set_focused_widget($field);
	ok shown($field)->cell( 3, 0 )->[1] & TB_REVERSE, 'the focused field shows the cursor after the text';
	press( $field, 'Shift+Left' );
	is $field->editor->selected_text,    'c',                                                  'Shift extends the selection';
	is shown($field)->cell( 2, 0 )->[2], $field->color_attr( $field->selection_color ),        'the selection is painted';
	is $field->cell( 0, 0 )->[2],        $field->color_attr( $field->focus_background_color ), 'the rest has the focus background';
};

subtest 'horizontal scrolling' => sub {
	my ( $field, $ui ) = text_field();
	type_text( $field, 'abcdefghij' );
	is row_text( $field, 0 ), 'defghij ', 'the end of the text and the cursor cell are visible';
	press( $field, 'Home' );
	is row_text( $field, 0 ), 'abcdefgh', 'Home scrolls back';
};

subtest 'keys that are not used bubble' => sub {
	my ( $field, $ui ) = text_field();
	my @bubbled;
	my $parent = $field->parent;
	$parent->on( KeyPress => sub { push @bubbled, $_[0]->key_name; return } );
	press( $field, $_ ) foreach qw(a Tab Up Escape Left);
	is \@bubbled, [qw(Tab Up Escape)], 'typing and editing keys stop, others bubble';

	$field->read_only(1);
	press( $field, $_ ) foreach qw(b Backspace Left);
	is [ $field->value, \@bubbled ], [ 'a', [qw(Tab Up Escape b Backspace)] ], 'a read-only field ignores edits and lets them bubble';
};

subtest 'placeholder and mask' => sub {
	my ( $field, $ui ) = text_field( placeholder => 'Name' );
	is row_text( $field, 0 ),     'Name    ',                                      'the placeholder shows while empty';
	is $field->cell( 0, 0 )->[1], $field->color_attr( $field->placeholder_color ), 'in its color';

	$field->mask('*');
	$field->value('secret');
	is row_text( $field, 0 ), '******  ', 'masked';
	is $field->value,         'secret',   'the value is not';
};

subtest 'mouse' => sub {
	my ( $field, $ui ) = text_field( value => 'one two' );
	click( $field, 1, 0 );
	is [ $field->editor->cursor ], [ 0, 1 ], 'a click places the cursor';
	click( $field, 3, 0, modifiers => TB_MOD_MOTION );
	is $field->editor->selected_text, 'ne', 'dragging selects';
	click( $field, 6, 0, modifiers => TB_MOD_SHIFT );
	is $field->editor->selected_text, 'ne tw', 'a click with Shift extends the selection';
	click( $field, 5, 0 );
	click( $field, 5, 0 );
	is $field->editor->selected_text, 'two', 'a double click selects a word';
};

subtest 'a masked field keeps its words to itself' => sub {
	my ($field) = text_field( value => 'open sesame', mask => '*' );
	Term::Fabulous::Editor->clipboard('before');
	press( $field, 'Ctrl+A' );
	press( $field, $_ ) foreach 'Ctrl+Insert', 'Ctrl+X', 'Shift+Delete';
	is [ Term::Fabulous::Editor->clipboard, $field->value ], [ 'before', 'open sesame' ], 'neither copied nor cut';

	press( $field, 'End' );
	press( $field, 'Ctrl+Left' );
	is [ $field->editor->cursor ], [ 0, 0 ], 'Ctrl+Left goes to the start';
	press( $field, 'Ctrl+Right' );
	is [ $field->editor->cursor ], [ 0, 11 ], 'Ctrl+Right to the end';
	press( $field, 'Ctrl+W' );
	is $field->value, '', 'Ctrl+W deletes the whole text before the cursor';

	$field->value('open sesame');
	click( $field, 1, 0 );
	click( $field, 1, 0 );
	is $field->editor->selected_text, 'open sesame', 'a double click selects all of it';

	$field->mask(undef);
	press( $field, 'Ctrl+Insert' );
	is( Term::Fabulous::Editor->clipboard, 'open sesame', 'without the mask copying works again' );
};

subtest 'disabled' => sub {
	my ( $field, $ui ) = text_field( value => 'x' );
	$ui->interaction->set_focused_widget($field);
	$field->disabled(1);
	ok !$field->is_focused, 'disabling removes the focus';
	ok !$field->can_focus,  'and keeps it away';
	press( $field, 'y' );
	is $field->value,                    'x',                                          'keys are ignored';
	is shown($field)->cell( 0, 0 )->[1], $field->color_attr( $field->disabled_color ), 'painted in the disabled color';
	$field->disabled(0);
	ok $field->can_focus, 'enabling lets it take the focus again';

	my ($unfocusable) = text_field( can_focus => 0 );
	ok !$unfocusable->can_focus, 'can_focus => 0 is kept';
	$unfocusable->disabled(1);
	$unfocusable->disabled(0);
	ok !$unfocusable->can_focus, 'and survives a disable/enable cycle';

	my ($toggled) = text_field( disabled => 1 );
	$toggled->can_focus(0);
	$toggled->disabled(0);
	ok !$toggled->can_focus, 'can_focus(0) while disabled counts once enabled';
	$toggled->disabled(1);
	is $toggled->can_focus(1), 0, 'can_focus(1) while disabled does not make it focusable';
	like dies { $toggled->can_focus( {} ) },   qr/\AClay::UI: 'can_focus' must be a plain boolean value/, 'a reference dies';
	like dies { $toggled->can_focus( 1, 0 ) }, qr/\AClay::UI: 'can_focus' takes one value/,               'so do two values';
	$toggled->disabled(0);
	ok $toggled->can_focus, 'but counts once enabled';
};

subtest 'accept restricts typing' => sub {
	my ( $field, $ui ) = text_field( accept => '0-9' );
	type_text( $field, 'a1b2' );
	is $field->value, '12', 'rejected keys are ignored';
	like dies { $field->value('x') }, qr/^Term::Fabulous::Widget::TextField: the text has characters that accept rejects: "x"/, 'the program may not set one';
	$field->accept(undef);
	type_text( $field, 'x' );
	is $field->value, '12x', 'undef lifts the restriction';
	like dies { $field->accept('a-z') }, qr/accept rejects: "12"/, 'a spec the text violates dies';
	is $field->accept, undef, 'and is not kept';

	my ($integer) = text_field( validator => 'integer' );
	type_text( $integer, '-4x2' );
	is $integer->value, '-42', 'a validator suggests the accept spec';
	my ($own) = text_field( validator => 'integer', accept => '0-9' );
	type_text( $own, '-4x2' );
	is $own->value, '42', 'an explicit accept wins over the suggestion';
	$own->validator(undef);
	type_text( $own, '-' );
	is $own->value, '42', 'and stays when the validator goes';
};

subtest 'required and validator' => sub {
	my ( $field, $ui ) = text_field( validator => 'email' );
	my @reports;
	$field->on( ValidityChange => sub { push @reports, [ $_[0]->is_valid, $_[0]->error ]; return } );
	ok $field->is_valid, 'an empty optional field is valid';
	type_text( $field, 'ada@' );
	is $field->error,                    'Please enter an e-mail address.',            'the message of the validator';
	is \@reports,                        [ [ 0, 'Please enter an e-mail address.' ] ], 'ValidityChange once when the message appeared';
	is $field->look_state,               'invalid',                                    'the look state';
	is shown($field)->cell( 0, 0 )->[1], $field->color_attr( $field->invalid_color ),  'painted in the invalid color';
	type_text( $field, 'example.com' );
	is [ $field->is_valid, scalar @reports ], [ 1, 2 ],     'and once when it went';
	is $reports[-1],                          [ 1, undef ], 'reported valid';
	is shown($field)->cell( 0, 0 )->[1],      $field->color_attr( $field->text_color ), 'painted in the text color again';

	$field->required(1);
	$field->value('');
	ok !$field->is_valid, 'an empty required field is invalid';
	is $field->error,    'Please fill in this field.', 'with the required message';
	is scalar @reports,  2,                            'a value set by the program reports nothing';
	is $field->validate, 'Please fill in this field.', 'validate reports it';
	is scalar @reports,  3,                            'and fires';
	$field->validate;
	is scalar @reports, 3, 'but not twice for the same message';
	$field->required_message('Name?');
	is $reports[-1], [ 0, 'Name?' ], 'a new message is reported';
	$field->disabled(1);
	is $field->look_state, 'disabled', 'disabled wins over invalid';
	$field->disabled(0);

	$field->validator( sub { $_[0] eq 'ok' ? undef : 'Say ok.' } );
	type_text( $field, 'no' );
	is $field->error, 'Say ok.',        'a code validator';
	is $reports[-1],  [ 0, 'Say ok.' ], 'reported on the change';
	like dies { $field->validator('mail') },    qr/unknown validator 'mail'/,         'an unknown name dies';
	like dies { text_field( required => [] ) }, qr/required must be a plain boolean/, 'required is checked';
};

subtest 'KDL limits come before the value' => sub {
	my $build = sub {
		my ($properties) = @_;
		return Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::TextField as Field\nField { $properties }" )->build;
	};
	my $field = $build->('value "42"; accept "0-9"; validator "integer"; required #true; required_message "Number?"');
	is [ $field->value, $field->accept, $field->validator->name, $field->required, $field->required_message ], [ '42', '0-9', 'integer', 1, 'Number?' ], 'every property is read';
	like dies { $build->('value "abc"; validator "integer"') }, qr/accept rejects: "abc"/, 'the validator limits a value before it';
};

subtest 'invalid_inputs' => sub {
	my $box   = Term::Fabulous::Widget::Box->new;
	my $inner = Term::Fabulous::Widget::Box->new;
	my $name  = Term::Fabulous::Widget::TextField->new( id => 'name', required  => 1 );
	my $port  = Term::Fabulous::Widget::TextField->new( id => 'port', validator => qr/\A[0-9]+\z/, value => '8080' );
	$inner->add_child($port);
	$box->add_child( $name, $inner );
	is [ map { $_->id } $box->invalid_inputs ], ['name'], 'the invalid inputs below a widget';
	$port->value('x');
	is [ map { $_->id } $box->invalid_inputs ],  [ 'name', 'port' ], 'in layout order';
	is [ map { $_->id } $port->invalid_inputs ], ['port'],           'a widget counts itself';
	$name->value('Ada');
	$port->value('80');
	is [ $box->invalid_inputs ], [], 'none when all are valid';
};

done_testing;
