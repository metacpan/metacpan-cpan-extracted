#!perl
use Test::More tests => 17;
use Test::Exception;
use Test::Deep;

use Pg::Explain::StringAnonymizer;

my $anonymizer;

lives_ok( sub { $anonymizer = Pg::Explain::StringAnonymizer->new() }, 'Base object creation' );
isa_ok( $anonymizer, 'Pg::Explain::StringAnonymizer' );

lives_ok( sub { $anonymizer->add( 'depesz' ) }, 'Adding string' );
lives_ok( sub { $anonymizer->add( 'yyy', 'xxx', 'c' ) }, 'Adding strings' );
lives_ok( sub { $anonymizer->add( [ qw( a b c ) ] ) }, 'Adding strings as arrayref' );

my @expected_keys = sort qw( depesz yyy xxx a b c );
my @existing_keys = sort keys %{ $anonymizer->{ 'strings' } };

cmp_deeply( \@existing_keys, \@expected_keys, "All keys are added" );

throws_ok( sub { $anonymizer->anonymized( 'depesz' ) },     qr{before\s+finalization}, '->anonymized() before finalize()' );
throws_ok( sub { $anonymizer->anonymization_dictionary() }, qr{before\s+finalization}, '->anonymization_dictionary() before finalize()' );

lives_ok( sub { $anonymizer->finalize() }, 'Finalization' );

lives_ok( sub { $anonymizer->anonymized( 'depesz' ) },     '->anonymized() after finalize()' );
lives_ok( sub { $anonymizer->anonymization_dictionary() }, '->anonymization_dictionary() after finalize()' );

throws_ok( sub { $anonymizer->add( 'whatevere' ) }, qr{after\s+finalization}, 'Adding strings after finalize()' );

$anonymizer = Pg::Explain::StringAnonymizer->new();
$anonymizer->add( "a", "b", "c" );

cmp_deeply(
    $anonymizer->{ 'strings' },
    {
        'a' => [ 16, 27, 27, 30, 8,  13, 31, 26, 20, 22, 19, 31, 25, 24, 10, 29, 3,  23, 14, 11, 19, 26, 23, 10, 29, 8,  27, 23, 12, 25, 29, 24 ],
        'b' => [ 29, 7,  11, 17, 30, 23, 23, 7,  25, 4,  22, 22, 27, 18, 15, 9,  5,  31, 30, 26, 26, 5,  29, 24, 23, 21, 4,  20, 3,  3,  28, 24 ],
        'c' => [ 16, 18, 18, 17, 13, 1,  0,  27, 20, 29, 29, 5,  22, 17, 18, 8,  27, 24, 22, 13, 1,  23, 30, 11, 6,  3,  21, 4,  13, 22, 29, 20 ],
    },
    'Simple anonymization with 3 strings',
);

$anonymizer->finalize();

cmp_deeply(
    $anonymizer->{ 'strings' },
    {
        'a' => 'quebec_three',
        'b' => 'five',
        'c' => 'quebec_sierra',
    },
    'Simple anonymization with 3 strings - post finalize',
);

is( $anonymizer->anonymized( 'a' ), 'quebec_three',  'Anonymization of "a" in ( "a", "b", "c" )' );
is( $anonymizer->anonymized( 'b' ), 'five',          'Anonymization of "b" in ( "a", "b", "c" )' );
is( $anonymizer->anonymized( 'c' ), 'quebec_sierra', 'Anonymization of "c" in ( "a", "b", "c" )' );
