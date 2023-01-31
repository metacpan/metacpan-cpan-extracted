use strict;
use Test::More;

use PICA::Data::Field;

my $f = PICA::Data::Field->new('123A', a => 1);

is $f->level, '1', 'level';
is $f->id, '123A', 'id';
is $f->occurrence, undef, 'occurrence';
is $f->occurrence('00'), undef, 'occurrence';
is $f->occurrence('2'), '02', 'occurrence';
is $f->id, '123A/02', 'id';

is $f->annotation, undef, 'annotation';
is_deeply $f, [qw(123A 02 a 1)], 'array';
is $f->annotation(' '), ' ', 'annotation';
is $f->annotation('?'), '?', 'annotation';
$f->set(a => 2);
is_deeply $f, [qw(123A 02 a 2 ?)], 'array';
is $f->annotation(''), undef, 'annotation';
is $f->annotation, undef, 'annotation';

$f->set(b => 0);
is_deeply $f, [qw(123A 02 a 2 b 0)], 'set';

done_testing;
