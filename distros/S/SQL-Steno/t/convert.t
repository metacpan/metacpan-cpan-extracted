use strict;
use warnings;

use SQL::Steno;

use Test::More tests => 10;



# Fake DBI
sub test($$;$) {
    local $_ = $_[0];
    &SQL::Steno::convert;
    is $_, $_[1], $_[2] || $_[0];
}

test ':d a,b,c;t;i>5',
    'select distinct a,b,c from t where i>5';

test ':q+0',
    'select date_format(now()-interval mod(month(now())+11,3) month,"%Y-%m-01")';

test ':{1..3,undef} :\{1..3,undef} :\#^{1..3,undef} :{"1,2"} :\{"1,2"} :\,{"1,2"} :{()}',
    "select 1,2,3,NULL '1','2','3','NULL' 1,2,3,NULL 1,2 '1,2' '1','2'";

test ';tabloid:ob2d5a9',
    'select * from tabloid order by 2 desc, 5 asc, 9';

SQL::Steno::Quote x => '-', 'o ';
SQL::Steno::Quote y => '-', 'a%||';
test q+:\;\#(1; a'a;	b;c), :\ !%&&(a b  c), :\a(a, b,c), :\x(a b c), :\y(a, b,c), b i\ "#(1 a"a b c), c i\ [#(1 a b c), d ni\{#(1,a,b,c)+,
    q!select 1,' a''a','	b','c', a&&b&&c, a&&b&&c, a||b||c, a||b||c, b in(1,"a""a","b","c"), c in(1,[a],[b],[c]), d not in(1,{a},{b},{c})!;

for my $repl ( ["'"], ['"'], ['`'], ['[', ']'], 0 ) {
     local $_ = ':j {:l} :j, {:l}}:l} :j, {:l\}:l} :j'; # bogus steno just for seeing that no conversion happens inside quotes
     if( $repl ) {
	 s/\{/$repl->[0]/g;
	 s/\}/$repl->[1]||$repl->[0]/eg;
     }
     my $in = $_;
     s/:j/join/g;
     test $in, "select $_";
}
#test 'ins tabloid;a=3', 'insert tabloid set a=3';
