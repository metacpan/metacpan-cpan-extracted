use strict;
use warnings;
use Test::More;
use Test::Database::Driver;

# fake the databases() method
my @db;
{
    no strict;
    @{"Test::Database::Driver::Zlonk::ISA"} = qw( Test::Database::Driver );
    *{"Test::Database::Driver::Zlonk::databases"} = sub {@db};
}

# our test plans
my @names = ( 0, 1, 3, 2, 4 );
my @expected = ( 0, 1, 2, 2, 4, 5 );

plan tests => 4 + @expected;

# check the basename
like( Test::Database::Driver::Zlonk->_basename(),
    qr/^tdd_zlonk_\w+_$/, "_basename looks correct" );

# test _set_key
my $bad = 'a b c';
ok( !eval { Test::Database::Driver->_set_key($bad); 1 }, "Bad key: $bad" );
like( $@, qr/^Invalid format for key '$bad' at/, 'Expected error message' );

# set a correct key
Test::Database::Driver->_set_key('clunk');
like( Test::Database::Driver::Zlonk->_basename(),
    qr/^tdd_zlonk_\w+_clunk_$/, "_basename looks correct (with key)" );

# now correctly compute our expectations
my $dbname = Test::Database::Driver::Zlonk->_basename();
@names    = map {"$dbname$_"} @names;
@expected = map {"$dbname$_"} @expected;

for my $expected (@expected) {
    is( Test::Database::Driver::Zlonk->available_dbname(),
        $expected, "available_dbname() = $expected" );
    push @db, shift @names;
}

