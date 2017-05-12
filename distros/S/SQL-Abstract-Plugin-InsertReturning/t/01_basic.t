use strict;
use warnings;

use Test::More;
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertReturning;

my $sql = SQL::Abstract->new;
can_ok($sql, 'insert_returning');

my ($insert, $returning);

$insert    = $sql->insert('pets', { name => 'Fluffy', type => 'cat' });
$returning = $sql->insert_returning('pets', { name => 'Fluffy', type => 'cat' });

is($returning, $insert, 'Without returning spec, runs same as SQL::Abstract->insert');

$returning = $sql->insert_returning('pets', { name => 'Fluffy', type => 'cat' }, [qw( name type )]);
like($returning, qr/RETURNING name, type$/, 'works with an array reference of columns');

$returning = $sql->insert_returning('pets', { name => 'Fluffy', type => 'cat' }, 'name');
like($returning, qr/RETURNING name$/, 'works with literal SQL');

$returning = $sql->insert_returning('pets', { name => 'Fluffy', type => 'cat' }, 'name, type');
like($returning, qr/RETURNING name, type$/, 'works with literal SQL');

my ($ret2, @binds) = $sql->insert_returning('pets', { name => 'Fluffy', type => 'cat' }, 'name, type');
is($returning, $ret2);
is_deeply(\@binds, [ 'Fluffy', 'cat' ]);

done_testing;
