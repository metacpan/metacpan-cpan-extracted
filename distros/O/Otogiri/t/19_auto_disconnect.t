#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Create test package to track disconnect method calls
{
    package TestOtogiri;
    use parent 'DBIx::Otogiri';
    
    our $disconnect_called = 0;
    
    sub disconnect {
        my $self = shift;
        $disconnect_called = 1;
        $self->SUPER::disconnect(@_);
    }
}

# Test with SQLite in-memory database
my $db = TestOtogiri->new(
    connect_info => ['dbi:SQLite::memory:', '', '']
);

# Verify that database handle is connected
ok($db->dbh->FETCH('Active'), 'Database is connected');

# Create table
$db->do(q{
    CREATE TABLE test_table (
        id INTEGER PRIMARY KEY,
        name TEXT
    )
});

# Insert data
$db->insert(test_table => {name => 'test'});

# Verify that data was inserted successfully
my $row = $db->single(test_table => {name => 'test'});
is($row->{name}, 'test', 'Data inserted successfully');

# Verify that disconnect has not been called yet
is($TestOtogiri::disconnect_called, 0, 'disconnect not called yet');

# Destroy object (DESTROY will be called)
undef $db;

# Verify that disconnect was automatically called
is($TestOtogiri::disconnect_called, 1, 'disconnect automatically called in DESTROY');

done_testing;