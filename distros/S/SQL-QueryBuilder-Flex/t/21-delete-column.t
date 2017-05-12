
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
    $q->delete_column('name')->delete_column(qr/note/);
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT email FROM user u',
        'checking delete_column'
    ;
    is
        join(' ', @params),
        '',
        'checking delete_column params'
    ;
}

done_testing();
