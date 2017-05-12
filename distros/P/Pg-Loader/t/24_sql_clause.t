use Pg::Loader::Misc;
use Test::More qw( no_plan );

*set_clause     = \& Pg::Loader::Query::_set_clause ;
*where_clause   = \& Pg::Loader::Query::_where_clause;

like set_clause(  ['name'], 'd' ),  
                 qr/SET \s* name=d.name \s* /ox;

like set_clause(  ['name', 'age'], 'd' ),  
                 qr/SET \s* name=d.name, \s* age=d.age \s*/ox;

is   where_clause( [qw( p1 )], 'overv', 'd') ,
                   'WHERE overv.p1=d.p1  ';

is   where_clause( [qw(p1 p2)], 'overv', 'd') ,
                   'WHERE overv.p1=d.p1  and  overv.p2=d.p2  ';


__END__
