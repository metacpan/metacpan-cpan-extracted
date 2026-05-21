use Mojo::Base -strict;
use Test::More;
use Mojo::SQLite;

# 1. Setup - Create a fresh, temporary DB
my $sql = Mojo::SQLite->new('sqlite::temp:');

# 2. Apply your role
my $db = $sql->db->with_roles("+InsertHelpers");


# 3. Create schema for testing
$db->query(<<'SQL');
CREATE TABLE fruits (
    fruit   TEXT,
    country TEXT,
    price   INTEGER,
    PRIMARY KEY (fruit, country)
);
SQL

# 4. Run tests
subtest 'insert_or_replace' => sub {
    $db->insert_or_replace('fruits', {fruit => 'Apple', country => 'Italy', price => 10});
    $db->insert_or_replace('fruits', {fruit => 'Apple', country => 'Italy', price => 20});
    
    my $res = $db->select('fruits', '*', {fruit => 'Apple'})->hash;
    is $res->{price}, 20, 'Price updated via replace';
};

subtest 'insert_or_ignore' => sub {
    $db->insert_or_ignore('fruits', {fruit => 'Orange', country => 'Spain', price => 5});
    $db->insert_or_ignore('fruits', {fruit => 'Orange', country => 'Spain', price => 50});
    
    my $res = $db->select('fruits', '*', {fruit => 'Orange'})->hash;
    is $res->{price}, 5, 'Second insert ignored, kept original price';
};

subtest 'insert_or_update' => sub {
    $db->insert_or_update('fruits', {fruit => 'Banana', country => 'Brazil', price => 1});
    $db->insert_or_update('fruits', {fruit => 'Banana', country => 'Brazil', price => 2});
    
    my $res = $db->select('fruits', '*', {fruit => 'Banana'})->hash;
    is $res->{price}, 2, 'Upsert worked correctly on composite PK';
};

done_testing();
