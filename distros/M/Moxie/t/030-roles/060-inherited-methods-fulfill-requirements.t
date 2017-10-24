#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Role::Table {
    use Moxie;

    sub query_by_id;
}

package Role::Table::RO {
    use Moxie;

    with 'Role::Table';

    sub query_by_id; # continue to defer this ...

    sub count;
    sub select;
}

package Table {
    use Moxie;

    extends 'Moxie::Object';
       with 'Role::Table';

    sub query_by_id { 'Table::query_by_id' }
}

package Table::RO {
    use Moxie;

    extends 'Table';
       with 'Role::Table::RO';

    sub count  { 'Table::RO::count' }
    sub select { 'Table::RO::select' }
}

my $t = Table::RO->new;
isa_ok($t, 'Table::RO');

can_ok($t, 'count');
can_ok($t, 'select');
can_ok($t, 'query_by_id');

is($t->count,       'Table::RO::count', '... got the expected values');
is($t->select,      'Table::RO::select', '... got the expected values');
is($t->query_by_id, 'Table::query_by_id', '... got the expected values');

done_testing;
