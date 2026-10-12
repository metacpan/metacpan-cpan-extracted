use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::OptionList;

sub list (@options) {
	return Term::Fabulous::OptionList->new( owner => 'My::Picker' )->set_options( [@options] );
}

subtest 'the three shapes of an option' => sub {
	my $list = list( 'Red', [ 'Dark green' => 'green' ], { label => 'Blue', value => 'b', disabled => 1 }, { label => 'Cyan' } );
	is [ $list->options ],
		[
		{ label => 'Red',        value => 'Red',   disabled => 0 },
		{ label => 'Dark green', value => 'green', disabled => 0 },
		{ label => 'Blue',       value => 'b',     disabled => 1 },
		{ label => 'Cyan',       value => 'Cyan',  disabled => 0 },
		],
		'a label, [ label, value ] and a hash, whose value defaults to the label';
	is [ $list->count, $list->label(1), [ $list->enabled_indexes ] ], [ 4, 'Dark green', [ 0, 1, 3 ] ], 'count, label and the enabled options';
	like dies { list( [ 1, 2, 3 ] ) }, qr/\AMy::Picker: an option must be a label, \[ label, value \] or \{ label => \.\.\., value => \.\.\., disabled => \.\.\. \}, got an ARRAY reference/,
		'other shapes die';
	like dies { list( { label => 'x', colour   => 1 } ) },  qr/a hash option takes only the keys 'label', 'value' and 'disabled'/, 'unknown keys die';
	like dies { list( { label => 'x', disabled => [] } ) }, qr/option disabled must be a plain boolean value/,                     'disabled is a boolean';
	like dies { list()->set_options('Red') }, qr/options must be an array reference/, 'options are a list';
};

subtest 'value lookup' => sub {
	my $list = list( 'Red', [ Green => 'g' ], [ Blue => 'b' ] );
	is $list->index_of_value('g'),                                                     1,                  'the index of a value';
	is [ $list->set_value('b')->selected_index, $list->value, $list->selected_label ], [ 2, 'b', 'Blue' ], 'selecting by value';
	like dies { $list->set_value('nope') }, qr/\AMy::Picker: no option has the value 'nope' at /, 'an unknown value dies';
	is $list->selected_index,                                                            2,                       'and keeps the selection';
	is [ $list->set_value(undef)->selected_index, $list->value, $list->selected_label ], [ undef, undef, undef ], 'undef selects none';
	like dies { $list->set_selected_index(3) }, qr/selected_index must be undef or an index in 0\.\.2, got '3'/, 'an index outside dies';
	$list->set_value('g');
	$list->set_options( [ [ Gold => 'g' ], 'Red' ] );
	is [ $list->selected_index, $list->selected_label ], [ 0, 'Gold' ], 'new options keep the selected value';
	$list->set_options( ['Red'] );
	is $list->selected_index, undef, 'and lose it when no option has it';
};

subtest 'disabled options and choose' => sub {
	my $list = list( 'Red', { label => 'Green', disabled => 1 }, 'Blue' );
	is $list->choose(2),                            1,        'choose reports a change';
	is $list->choose(2),                            0,        'and none for the selected option';
	is [ $list->choose(1), $list->selected_index ], [ 0, 2 ], 'a disabled option cannot be chosen';
	is $list->set_value('Green')->selected_index,   1,        'the program can select one';
	$list->set_disabled( 1, 0 );
	is [ $list->is_disabled(1), [ $list->enabled_indexes ] ], [ 0, [ 0, 1, 2 ] ], 'set_disabled';
	like dies { $list->choose(3) },       qr/choose needs an option index in 0\.\.2, got '3'/,           'choose checks the index';
	like dies { $list->is_disabled(-1) }, qr/option_disabled needs an option index in 0\.\.2, got '-1'/, 'and so does is_disabled';
};

done_testing;
