use strict;
use warnings;

use SQL::Steno;
$SQL::Steno::prompt = $SQL::Steno::contprompt = '';
$SQL::Steno::echo = 1;

use Test::More tests => 1;



# Fake DBI
{
    $SQL::Steno::dbh = bless {}, 'DBI::db::test';
    package DBI::st::test;

    my $preparation = 0;
    my @rows;
    sub DBI::db::test::prepare {
	if( $_[1] =~ /^show/ ) {	# only prepare if query is show
	    @rows = [1, qw(me 1.2.3.4:1234 shelldb Query), 0, undef, $_[1], '0.000'];
	    unshift @rows, [(0) x 6, 'Sleep'] if $preparation & 1; # add some varying cruft to be grepped away
	    push @rows, [(0) x 6, 'Sleep'] if $preparation & 2;
	    ++$preparation;
	}
	$DBI::rows = @rows;
	bless {
	    Active => 1,
	    NAME => [qw(Id User Host db Command Time State Info Progress)]
	};
    }

    sub execute {}

    sub fetchrow_array {
	@rows ? @{shift @rows} : ();
    }
}



my $ofh = select;
close STDOUT;
open STDOUT, '>:utf8', \my $str;
open STDIN, '<&DATA';
SQL::Steno::shell;
close STDOUT;
select $ofh;

$str =~ s/(\nprepare: )[\d.]+(s   execute: )[\d.]+/${1}0.000${2}0.000/g;


is $str, <<\OUT;
&{ print "let's test\n"; '&s num;' || 'perverse concatenation' }123
let's test
set @num=123;
prepare: 0.000s   execute: 0.000s   rows: 0
&ss(str;foo 'bar)
set @str='foo ''bar';
prepare: 0.000s   execute: 0.000s   rows: 0
&sdt epoch;1970-01-01 00:00
set @epoch=cast('1970-01-01 00:00' as datetime);
prepare: 0.000s   execute: 0.000s   rows: 0
?&st
&st     var;value   set @var = cast("value" as time)
&sy
select @a:=date(now()-interval 1 day)`@a`, @z:=date(now())-interval 1 second`@z`;
prepare: 0.000s   execute: 0.000s   rows: 0
&ps
prepare: 0.000s   execute: 0.000s   rows: 1
Id
 |User
 |  |Host        |db     |Command
 |  |            |       |     |Time
 |  |            |       |     | |State
 |  |            |       |     | | |Info            |Progress
-|--|------------|-------|-----|-|-|----------------|-----|
1|me|1.2.3.4:1234|shelldb|Query|0|ω|show processlist|0.000|
&-
&ps
prepare: 0.000s   execute: 0.000s   rows: 2
- Id:       1
  User:     me
  Host:     "1.2.3.4:1234"
  db:       shelldb
  Command:  Query
  Time:     0
  State:    ~
  Info:     show processlist
  Progress: 0.000
&.csv( tab )&psf
prepare: 0.000s   execute: 0.000s   rows: 2
Id	User	Host	db	Command	Time	State	Info	Progress
1	me	1.2.3.4:1234	shelldb	Query	0		show full processlist	0.000
&.csv( semi; tab )&psf
prepare: 0.000s   execute: 0.000s   rows: 3
Id;User;Host;db;Command;Time;State;Info;Progress
1;me;1.2.3.4:1234;shelldb;Query;0;;show full processlist;0.000
&.csv
/Show/i{ $_[8] =~ s/up/off/ }!/up|Info/=show up
prepare: 0.000s   execute: 0.000s   rows: 1
Id,User,Host,db,Command,Time,State,Info,Progress
1,me,1.2.3.4:1234,shelldb,Query,0,,show off,0.000
{ 'just a nop' }a,b,c;tbl;
a>5
select a,b,c from tbl where
a>5;
prepare: 0.000s   execute: 0.000s   rows: 0
/match me/x,y,z
;tbl
;x<9
select x,y,z
 from tbl
 where x<9;
prepare: 0.000s   execute: 0.000s   rows: 0
&{ Query abc => 'doc', '($1|$>|$*) ($\#%$1|$\#%$>|$\#%$*) ($\1|$\>|$\*) ($\,>|$\,*)' }
&abc 1,2;3,4;5,6,7
select (1,2|3,4,5,6,7|1,2,3,4,5,6,7) (1$2|'3,4'$'5,6,7'|'1,2'$'3,4'$'5,6,7') ('1','2'|'3,4','5,6,7'|'1,2','3,4','5,6,7') ('3','4','5','6','7'|'1','2','3','4','5','6','7');
prepare: 0.000s   execute: 0.000s   rows: 0
&{ Query xyz => 'doc', "\$\\'0, ".'1 $\`2, $\"1, $\[2, $\{}1, $\> | $\[> | $\{}* |$\"19, $\[20' }
?&xyz
&xyz    doc
&xyz 1"x;2`x;3'x;4
select 'xyz', 1 `2``x`, "1""x", [2`x], {1"x}, '3''x','4' | [3'x],[4] | {1"x},{2`x},{3'x},{4} |,;
prepare: 0.000s   execute: 0.000s   rows: 0
?\a
\a      and: unquoted joined with &&
OUT



__DATA__
&{ print "let's test\n"; '&s num;' || 'perverse concatenation' }123
&ss(str;foo 'bar)
&sdt epoch;1970-01-01 00:00
?&st
&sy
&ps
&-
&ps
&.csv( tab )&psf
&.csv( semi; tab )&psf
&.csv
/Show/i{ $_[8] =~ s/up/off/ }!/up|Info/=show up

{ 'just a nop' }a,b,c;tbl;\
a>5

\\/match me/x,y,z
;tbl
;x<9\\
&{ Query abc => 'doc', '($1|$>|$*) ($\#%$1|$\#%$>|$\#%$*) ($\1|$\>|$\*) ($\,>|$\,*)' }
&abc 1,2;3,4;5,6,7
&{ Query xyz => 'doc', "\$\\'0, ".'1 $\`2, $\"1, $\[2, $\{}1, $\> | $\[> | $\{}* |$\"19, $\[20' }
?&xyz
&xyz 1"x;2`x;3'x;4
?\a
