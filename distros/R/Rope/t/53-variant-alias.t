use Test::More;
use Rope;

{
    package Test::Parser::One;
 
    use Moo;
 
    sub parse {
        return 'parse string';
    }
 
    sub parse_file {
        return 'parse file';
    }
}
 
{
    package Random::Parser::Two;
 
    use Moo;
 
    sub parse_string {
        return 'parse string';
    }
 
    sub parse_from_file {
        return 'parse file';
    }
}
 
{
    package Another::Parser::Three;
 
    use Moo;
 
    sub meth_one {
        return 'parse string';
    }
 
    sub meth_two {
        return 'parse file';
    }
}

{
	package Locked;

	use Rope;
	use Rope::Autoload;
	use Rope::Variant;
	use Types::Standard qw/Object/;

	variant parser => (
		given => Object,
		when => [
			'Test::Parser::One' => {
				alias => {
					parse_string => 'parse',
					# parse_file exists 
				},
			},
			'Random::Parser::Two' => {
				alias => {
					# parse_string exists
					parse_file   => 'parse_from_file', 
				},
			},
			'Another::Parser::Three' => {
				alias => { 
					parse_string => 'meth_one',
					parse_file   => 'meth_two', 
				},
			},
		],
	);

	1;
}

my $k = Locked->new(parser => Test::Parser::One->new);

is($k->parser->parse_string, 'parse string');
is($k->parser->parse_file, 'parse file');

$k->parser = Random::Parser::Two->new();

is($k->parser->parse_string, 'parse string');
is($k->parser->parse_file, 'parse file');

$k->parser = Another::Parser::Three->new();

is($k->parser->parse_string, 'parse string');
is($k->parser->parse_file, 'parse file');

ok(1);

done_testing();
