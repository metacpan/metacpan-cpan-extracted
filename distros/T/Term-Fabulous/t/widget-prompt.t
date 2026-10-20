use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Object::Pad 0.825;

use Clay::XS qw(sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::TextField;

my $Prompt = 'Term::Fabulous::Widget::Prompt';

my $root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $behind   = Term::Fabulous::Widget::TextField->new( value => 'behind' );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 70, height => 20 );
my $ui       = Term::Fabulous->new( width => 70, height => 20, root => $root, terminal => $terminal );
$root->add_child($behind);

sub keys_ (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub focused () {
	return $ui->interaction->get_focused_widget;
}

# Records the answers of a prompt, and where the focus was when each came.
sub recorded ($prompt) {
	my @answers;
	$prompt->on( Answer => sub ($event) { push @answers, { button => $event->button, values => $event->values, dismissed => $event->dismissed, focus => focused() }; return } );
	return \@answers;
}

$ui->interaction->set_focused_widget($behind);
$ui->step;

subtest 'confirm: a button answers, and the focus is back first' => sub {
	my $prompt  = $Prompt->confirm( $ui, title => 'Quit?', message => 'Unsaved [bold]notes[/] are lost.', ok => 'Quit' );
	my $answers = recorded($prompt);
	ok $prompt->is_open, 'confirm opens the prompt';
	is [ $prompt->button_ids ], [qw(ok cancel)], 'the buttons ok and cancel';
	ref_is focused(), $prompt->button('ok'), 'the first button has the focus';
	keys_('Enter');
	ok !$prompt->is_open, 'Enter on a button answers and closes';
	is scalar @$answers,         1,    'one answer';
	is $answers->[0]{button},    'ok', 'with the button pressed';
	is $answers->[0]{dismissed}, 0,    'not dismissed';
	ref_is $answers->[0]{focus}, $behind, 'the focus was back on the widget behind when the answer came';
};

subtest 'Escape dismisses with cancel' => sub {
	my $prompt  = $Prompt->confirm( $ui, title => 'Delete?', focus => 'cancel' );
	my $answers = recorded($prompt);
	ref_is focused(), $prompt->button('cancel'), 'focus names the button that starts with the focus';
	keys_('Escape');
	is [ map { [ $_->{button}, $_->{dismissed} ] } @$answers ], [ [ 'cancel', 1 ] ], 'Escape answers cancel, dismissed';
	$prompt->open($ui);
	keys_('Enter');
	is [ map { [ $_->{button}, $_->{dismissed} ] } @$answers ], [ [ 'cancel', 1 ], [ 'cancel', 0 ] ], 'a prompt opens again and answers once per opening; the Cancel button is not dismissed';
};

subtest 'Close comes before Answer' => sub {
	for my $how ( 'Escape', 'button' ) {
		my $prompt = $Prompt->confirm( $ui, title => 'Order' );
		my @order;
		$prompt->on( Close  => sub { push @order, 'Close';  return } );
		$prompt->on( Answer => sub { push @order, 'Answer'; return } );
		$how eq 'Escape' ? keys_('Escape') : $prompt->answer('cancel');
		is \@order, [qw(Close Answer)], "after $how";
	}
};

subtest 'ask: one text field, Enter presses the default button' => sub {
	my $prompt  = $Prompt->ask( $ui, title => 'Rename', label => 'Name', value => 'notes.txt', required => 1 );
	my $answers = recorded($prompt);
	ref_is focused(), $prompt->input('value'), 'the field has the focus';
	$terminal->type_text('todo.md');
	keys_('Enter');
	is $answers->[0]{button},        'ok',      'Enter in the field presses the default button';
	is $answers->[0]{values}{value}, 'todo.md', 'typing replaced the selected text';
};

subtest 'a primary button checks the inputs first' => sub {
	my $name   = Term::Fabulous::Widget::TextField->new( required  => 1, layout => { sizing => { width => sizing_grow() } } );
	my $email  = Term::Fabulous::Widget::TextField->new( validator => 'email', value => 'ada', layout => { sizing => { width => sizing_grow() } } );
	my $prompt = $Prompt->new(
		title   => 'New contact',
		fields  => [ { name => 'name', label => 'Name', input => $name }, { name => 'email', label => 'E-mail', input => $email } ],
		buttons => [ { id => 'add', label => 'Add', primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
		check   => sub ($values) { return $values->{name} eq 'Bob' ? 'Bob is already a contact.' : undef },
	);
	my $answers = recorded($prompt);
	$prompt->open($ui);
	$prompt->answer('add');
	ok $prompt->is_open, 'an empty required field keeps the prompt open';
	is $prompt->error, 'Name: Please fill in this field.', 'the error line names the field';
	ref_is focused(), $name, 'and the field gets the focus';

	$terminal->type_text('Bob');
	$ui->step;
	$prompt->answer('add');
	like $prompt->error, qr/\AE-mail: /, 'the next field that is wrong';
	ref_is focused(), $email, 'gets the focus';

	$email->value('ada@example.org');
	$prompt->answer('add');
	is $prompt->error, 'Bob is already a contact.', 'the check of the whole prompt runs after the inputs';

	$name->value('Ada');
	$prompt->answer('add');
	ok !$prompt->is_open, 'all fine: the prompt answers';
	is $answers->[0]{values}, { name => 'Ada', email => 'ada@example.org' }, 'with the values by field name';

	$prompt->open($ui);
	is $prompt->error, undef, 'opening again empties the error line';
	$name->value('');
	$prompt->answer('cancel');
	is $answers->[1]{button}, 'cancel', 'a button that is not primary answers without checking';
};

# An input made of other inputs: a box that cannot take the focus
# itself, with a text field inside that checks the value.
class Pair :isa(Term::Fabulous::Widget::Box) {
	use Clay::XS qw(sizing_grow);

	field $text :reader;
	ADJUST {
		$text = Term::Fabulous::Widget::TextField->new( required => 1, layout => { sizing => { width => sizing_grow() } } );
		$self->add_child($text);
	}
	method value ()    { return $text->value }
	method validate () { return $text->validate }
}

subtest 'an input that cannot take the focus passes it inside' => sub {
	my $pair   = Pair->new( layout => { sizing => { width => sizing_grow() } } );
	my $prompt = $Prompt->new(
		fields  => [ { name => 'pair', label => 'Pair', input   => $pair } ],
		buttons => [ { id   => 'ok',   label => 'OK',   primary => 1 }, { id => 'cancel', label => 'Cancel' } ],
		focus   => 'pair',
	);
	$prompt->open($ui);
	ref_is focused(), $pair->text, 'focus names the input: its text field gets the focus';
	$ui->interaction->set_focused_widget( $prompt->button('ok') );
	$prompt->answer('ok');
	is $prompt->error, 'Pair: Please fill in this field.', 'an invalid input keeps the prompt open';
	ref_is focused(), $pair->text, 'and its text field gets the focus';
	$prompt->answer('cancel');
};

subtest 'alert, title and message' => sub {
	my $prompt = $Prompt->alert( $ui, message => 'Copied 3 files.', ok => 'Fine' );
	is [ $prompt->button_ids ], ['ok'], 'one button';
	is $prompt->title,          '',     'no title';
	$prompt->title('Done');
	is $prompt->children->[0]->text, 'Done', 'a title set later goes first';
	$prompt->message('');
	is scalar( grep { $_->isa('Term::Fabulous::Widget::Text') } @{ $prompt->children } ), 1, 'an empty message takes it away; the title stays';
	$prompt->close;
};

subtest 'a prompt fits a narrow screen' => sub {
	my $narrow_root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $narrow_terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 16 );
	my $narrow          = Term::Fabulous->new( width => 40, height => 16, root => $narrow_root, terminal => $narrow_terminal );
	$narrow->step;
	my $prompt = $Prompt->alert( $narrow, title => 'Saved', message => 'The notes are in notes.txt, next to the program.' );
	$narrow->step;
	is $narrow->bounding_box($prompt)->{width}, 40, 'as wide as the screen, not 60 columns';
	$prompt->close;
	$ui->step;
	$prompt = $Prompt->alert( $ui, title => 'Saved', width => 30 );
	$ui->step;
	is $ui->bounding_box($prompt)->{width}, 30, 'and as wide as asked where there is room';
	$prompt->close;
};

subtest 'checks' => sub {
	my $field = Term::Fabulous::Widget::TextField->new;
	like dies { $Prompt->new( buttons => [] ) },                                                           qr/buttons must be a non-empty array reference/,              'a prompt needs a button';
	like dies { $Prompt->new( buttons => [ { id => 'ok' } ] ) },                                           qr/the label of the button 'ok' must be a string, got undef/, 'a button needs a label';
	like dies { $Prompt->new( buttons => [ { id => 'a', label => 'A' }, { id => 'a', label => 'B' } ] ) }, qr/two buttons have the id 'a'/,                              'ids are unique';
	like dies { $Prompt->new( fields  => [ { name => 'x', input => 'text' } ] ) },                 qr/the field 'x' needs an input widget that has a value, got 'text'/, 'a field needs an input';
	like dies { $Prompt->new( fields  => [ { name => 'x', input => $field, size => 3 } ] ) },      qr/the field 'x' has unknown keys: size/,                             'unknown keys die';
	like dies { $Prompt->new( fields  => [ { name => 'ok', input => $field } ], focus => 'ok' ) }, qr/focus 'ok' names both a field and a button/,                       'an ambiguous focus dies';
	like dies { $Prompt->new( focus   => 'nope' ) },                                               qr/focus 'nope' names no field and no button/,                        'an unknown focus dies';
	like dies { $Prompt->new( width   => 0 ) },                                                    qr/width must be a positive integer, got '0'/,                        'a width of 0 dies';
	like dies { $Prompt->new->answer('ok') },   qr/\ATerm::Fabulous::Widget::Prompt: answer needs an open dialog/,                 'answering a closed prompt dies';
	like dies { $Prompt->new->answer('nope') }, qr/\ATerm::Fabulous::Widget::Prompt: the dialog has no button with the id 'nope'/, 'an unknown button dies';
};

done_testing;
