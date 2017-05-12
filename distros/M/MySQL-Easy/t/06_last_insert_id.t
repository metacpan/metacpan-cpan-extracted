
use strict;
use Test;
use Cwd;
use MySQL::Easy;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 1;
    my $dbo = MySQL::Easy->new("stocks");
       $dbo->do("create temporary table blarg( i int unsigned not null auto_increment primary key, j int unsigned not null )");
    my $sth = $dbo->ready("insert into blarg(j) values(?)");
       $sth->execute(int 256*rand) for 1 .. 10;

    ok( $dbo->last_insert_id, 10 );

} else {
    plan tests => 1;
    ok(1);
}

