
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 4;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->limit(0, 10)
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u LIMIT ?, ?',
        'checking LIMIT'
    ;
    is
        join(' ', @params),
        '0 10',
        'checking LIMIT params'
    ;
}

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->limit(10)
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u LIMIT ?',
        'checking LIMIT 2'
    ;
    is
        join(' ', @params),
        '10',
        'checking LIMIT 2 params'
    ;
}

done_testing();
