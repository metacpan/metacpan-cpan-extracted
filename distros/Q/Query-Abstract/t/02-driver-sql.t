#!/usr/bin/perl

use Test::More;

BEGIN {
    use_ok( 'Query::Abstract' ) || print "Bail out!\n";
}

my $fm = Query::Abstract->new( driver => ['SQL' => [ table => 'users' ] ] );
isa_ok($fm, 'Query::Abstract', 'Should create Query::Abstract instance');

subtest 'Simplest "eq" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { eq => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname = ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};


subtest 'Simplest "ne" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { ne => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname <> ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "lt" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { lt => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname < ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "le" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { le => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname <= ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "gt" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { gt => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname > ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "ge" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { ge => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname >= ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "<" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { '<' => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname < ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "<=" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { '<=' => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname <= ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest ">" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { '>' => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname > ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest ">=" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ fname => { '>=' => 'ivan' } ] );
    
    is($sql, 'SELECT * FROM users WHERE fname >= ?', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Simplest "like" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ lname => { like => 'iva%' } ] );
    
    is($sql, 'SELECT * FROM users WHERE lname LIKE ?', 'Should return valid SQL');
    is_deeply($bind_values, ['iva%'], 'Should return valid bind values');
};

subtest 'Simplest "in" query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ lname => ['ivan', 'taras'] ] );
    
    is($sql, 'SELECT * FROM users WHERE lname IN (?, ?)', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan', 'taras'], 'Should return valid bind values');
};

subtest 'Simplest "in" query. Full notation' => sub {
    my ($sql, $bind_values) = $fm->convert_query( [ lname => { 'in' => ['ivan', 'taras'] } ] );
    
    is($sql, 'SELECT * FROM users WHERE lname IN (?, ?)', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan', 'taras'], 'Should return valid bind values');
};

subtest 'Simplest "eq" query with DESC sort ' => sub {
    my ($sql, $bind_values) = $fm->convert_query( where => [ fname => { eq => 'ivan' } ], sort_by => 'id DESC' );
  
    is($sql, 'SELECT * FROM users WHERE fname = ? ORDER BY id DESC', 'Should return valid SQL');
    is_deeply($bind_values, ['ivan'], 'Should return valid bind values');
};

subtest 'Complex query' => sub {
    my ($sql, $bind_values) = $fm->convert_query( 
        where => [
            fname => { eq => 'taras' },
            id => {'<' => 5},
            lname => ['Leleka', 'Ivanov'],
            lname => { in => ['Klitchko'] },
            age   => { ne => '50' }
        ],
        sort_by => ['fname DESC', 'age'],
    );

    is($sql, 'SELECT * FROM users WHERE fname = ? AND id < ? AND lname IN (?, ?) AND lname IN (?) AND age <> ? ORDER BY fname DESC ,age ASC', 'Should return valid SQL');
    is_deeply($bind_values, ['taras', '5', 'Leleka', 'Ivanov', 'Klitchko', 50], 'Should return valid bind values');
};


done_testing();