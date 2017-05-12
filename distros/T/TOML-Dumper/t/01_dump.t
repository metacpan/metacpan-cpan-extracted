use strict;
use warnings;
use Test::More 0.98;

use TOML::Dumper;

my $expected = do { local $/; <DATA> }; chomp $expected;
my $data = {
    string  => "hoge",
    integer => 12,
    number  => 34.56,
    false   => \0,
    true    => \1,
    hash    => {
        string  => "fuga",
        integer => 12,
        number  => 34.56,
    },
    array => [1, 2, 3, 4],
    array_of_table => [
        {
            string  => "foo",
            integer => 12,
            number  => 34.56,
        },
        {
            string => "wai wai",
            integer => 12,
            number => 34.56,
        },
        {
            string  => "wai \twai",
            integer => 12,
            number  => 34.56,
            nest    => [
                {
                    nest2 => [[1, 2, 3], [{}]]
                }
            ],
            nest3 => {
                nest4 => { nest5 => [[1],[[[[2],[3,4]],[5]],[6]]] },
            },
        },
    ],
};

my $result = TOML::Dumper->new()->dump($data);
is $result, $expected, 'mixed';

if ($ENV{AUTHOR_TESTING}) {
    require TOML::Parser;
    my $result = TOML::Dumper->new->dump(TOML::Parser->new->parse($expected));
    is $result, $expected, 'reparse';
}

done_testing;
__DATA__
false = false
integer = 12
number = 34.56
string = "hoge"
true = true
array = [1, 2, 3, 4]

[[array_of_table]]
integer = 12
number = 34.56
string = "foo"

[[array_of_table]]
integer = 12
number = 34.56
string = "wai wai"

[[array_of_table]]
integer = 12
number = 34.56
string = "wai \twai"

[[array_of_table.nest]]
nest2 = [[1, 2, 3], [{}]]

[array_of_table.nest3]

[array_of_table.nest3.nest4]
nest5 = [[1], [[[[2], [3, 4]], [5]], [6]]]

[hash]
integer = 12
number = 34.56
string = "fuga"
