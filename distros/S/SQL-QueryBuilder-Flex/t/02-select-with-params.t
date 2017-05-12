
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 2;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL
        ->select(
            'name',
            'email',
            [ 'SUBSTRING(note, ?, ?)', 'note', 0, 10 ],
        )
        ->from('user', 'u')
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email, SUBSTRING(note, ?, ?) AS note FROM user u',
        'checking SELECT'
    ;
    is
        join(' ', @params),
        '0 10',
        'checking SELECT params'
    ;
}

1;
