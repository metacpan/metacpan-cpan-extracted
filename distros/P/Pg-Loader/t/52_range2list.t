use Pg::Loader::Query;
use Test::More qw( no_plan );

*range2list = \&Pg::Loader::Query::range2list;
*ranges2set = \&Pg::Loader::Query::ranges2set;

is  range2list('2'),          '2';
is  range2list('1-2'),        '1..2';
is  range2list(''),           '';
is  range2list('1-2,5'),      '1..2,5';
is  range2list('1-2,5,1-2'),  '1..2,5,1..2';
is  range2list('1-2,1-2')  ,  '1..2,1..2';
is  range2list('1,2')      ,  '1,2';

is  range2list('-0')       ,  '';
is  range2list('-2')       ,  '';
is  range2list('-1-2')     ,  '';
is  range2list('1-2-')     ,  '';

#is  range2list('3,1-2-')   ,  '';
is_deeply  ranges2set('1-2,2'),  [1,2];
is_deeply  ranges2set('0-2,4-4'),  [0,1,2,4];
is_deeply  ranges2set('0-0'),  [0];
is_deeply  ranges2set('2'),    [2];
is   ranges2set(''), undef;
