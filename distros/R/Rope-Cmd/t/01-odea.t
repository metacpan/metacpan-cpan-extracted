use Test::More;

{
	package Rope::Cmd::Test;

	use Rope::Cmd;

	use Coerce::Types::Standard qw/JSON Str/;

	title 'This is the title of the command line application';

	abstract 'This is the abstract of the command line application';

	option one => (
		type => Str,
		description => 'This is one',
		option_alias => 'o'
	);

	option two => (
		type => Str,
		description => 'This is two'
	);

	option json => (
		type => JSON->by('decode'),
		coerce_type => 1,
		description => 'This is json'
	);

	sub callback {
		my ($self) = @_;
		$self->one = 'Okay Extra';
	}

	1;
}

my $options = Rope::Cmd::Test->options;

Rope::Cmd::Test->run('help');;

my $result = Rope::Cmd::Test->run('o=other', 'two=thing', 'json=["one","two"]');

is($result->one, 'Okay Extra');

is($result->two, 'thing');

is_deeply($result->json, [qw/one two/]);

done_testing(3);
