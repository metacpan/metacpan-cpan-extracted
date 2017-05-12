
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 1;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL->select(
            'name',
            'email',
        )
        ->from('user')
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user',
        'checking alias'
    ;
}

1;
