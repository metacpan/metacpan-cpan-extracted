use Test::More;

use Types::Standard qw/Str Object/;

{
    package One::Two::Three;

    use Moo;
    with 'MooX::VariantAttribute::Role';    
}

my $obj = One::Two::Three->new();

my $when = {
    'one' => { 
        run => sub { return "$_[1] - cold, cold, cold inside" },
    },
    'two' => {
        run => sub { return "$_[1] - don't look at me that way"; },
    },
    'three' => {
        run => sub { return "$_[1] - how hard will i fall if I live a double life"; },
    },
};

is $obj->_find_from_given('one', Str, $when, 'test'), 'one', 'okay we have one';
is $obj->_find_from_given('two', Str, $when, 'test'), 'two', 'okay we have two';
is $obj->_find_from_given('three', Str, $when, 'test'), 'three', 'okay we have three';

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

my $when2 = {    
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
};

my $parser = Random::Parser::Two->new();
my $parsers = $obj->_find_from_given($parser, Object, $when2);
is( $parsers, 'Random::Parser::Two', 'alias' );

my $when3 = {    
    'SCALAR' => {
        run => sub { return 'I am a SCALAR' },
    },
    'HASH' => {
        run => sub { return 'I am a HASH' },
    },
    'ARRAY' => {
        run => sub { return 'I am a ARRAY' },
    },
};

my $scalar = $obj->_find_from_given('HEY', sub { ref $_[1] or ref \$_[1] }, $when3, 'test');
is( $scalar, 'SCALAR', 'ref SCALAR' );
my $hash = $obj->_find_from_given({ one => 'two' }, sub { ref $_[1] }, $when3, 'test');
is( $hash, 'HASH', 'ref HASH' );
my $array = $obj->_find_from_given([qw/one two/], sub { ref $_[1] }, $when3, 'test');
is( $array, 'ARRAY', 'ref ARRAY' );

done_testing();
