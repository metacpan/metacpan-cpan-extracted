use Test::More;

use Types::Standard qw/Str Object/;

{
    package One::Two::Three;

    use Moo;
    with 'MooX::VariantAttribute::Role';
   
    has test => (
        is => 'rw',
    );
    
}

my $obj = One::Two::Three->new();

my $when = [
    'one' => { 
        run => sub { return "$_[1] - cold, cold, cold inside" },
    },
    'two' => {
        run => sub { return "$_[1] - don't look at me that way"; },
    },
    'three' => {
        run => sub { return "$_[1] - how hard will i fall if I live a double life"; },
    },
];

is $obj->_given_when('one', Str, $when, 'test'), 'one - cold, cold, cold inside', 'okay we have one';
is $obj->_given_when('two', Str, $when, 'test'), 'two - don\'t look at me that way', 'okay we have two';
is $obj->_given_when('three', Str, $when, 'test'), 'three - how hard will i fall if I live a double life', 'okay we have three';

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

my $when2 = [
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
];

my $parser = Random::Parser::Two->new();
my $parser = $obj->_given_when($parser, Object, $when2, 'test');
is( $parser->parse_file, 'parse file', 'alias' );

my $when3 = [    
    'SCALAR' => {
        run => sub { return 'I am a SCALAR' },
    },
    'HASH' => {
        run => sub { return 'I am a HASH' },
    },
    'ARRAY' => {
        run => sub { return 'I am a ARRAY' },
    },
];

my $scalar = $obj->_given_when('HEY', sub { ref $_[1] or ref \$_[1] }, $when3, 'test');
is( $scalar, 'I am a SCALAR', 'ref SCALAR' );
my $hash = $obj->_given_when({ one => 'two' }, sub { ref $_[1] }, $when3, 'test');
is( $hash, 'I am a HASH', 'ref HASH' );
my $array = $obj->_given_when([qw/one two/], sub { ref $_[1] }, $when3, 'test');
is( $array, 'I am a ARRAY', 'ref ARRAY' );

done_testing();
