use Pg::Corruption;
use Test::More qw( no_plan );

*schema_name = \&Pg::Corruption::schema_name;


is_deeply [ schema_name('person')],         [ 'public', 'person' ] ;
is_deeply [ schema_name('person', 'b')],    [ 'b', 'person'      ] ;
is_deeply [ schema_name('a.person')],       [ 'a', 'person'      ] ;
is_deeply [ schema_name('a.b.c')],          [ 'a', 'b.c'         ] ;
is_deeply [ schema_name('a.b', 'def')],     [ 'a', 'b'           ] ;

ok  !schema_name('');
ok  !schema_name();
#ok  !schema_name(' ');

#is_deeply [ schema_name('')],               [ ()                 ] ;
