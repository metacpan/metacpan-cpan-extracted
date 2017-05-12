
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 1;

use SQL::QueryBuilder::Flex 'SQL';


{
    my $q = SQL
        ->select('u.name')
        ->from('user', 'u')
        ->from('group', 'g')
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT u.name FROM user u, group g',
        'checking multi FROM'
    ;
}

done_testing();
