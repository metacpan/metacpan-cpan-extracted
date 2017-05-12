
use strict;
use Test;
use Cwd;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    use strict;
    use MySQL::Easy;

    plan tests => 12;

    my $dbo = new MySQL::Easy("scratch");

    $dbo->do("drop table if exists easy_test");
    $dbo->do('create table easy_test( id int unsigned not null auto_increment primary key )');

    my $put  = $dbo->ready("insert into easy_test set id=?");
    my $get1 = $dbo->ready("select id           from easy_test where id=?");
    my $get2 = $dbo->ready("select 2*id oid, id from easy_test where id=?");

    $put->execute( 7 ) or die $dbo->errstr; ok(1);
    $put->execute( 8 ) or die $dbo->errstr; ok(1);
    $put->execute( 9 ) or die $dbo->errstr; ok(1);

    for my $id (7, 8, 9) {
        execute $get1( $id ) or die $dbo->errstr;
        if( my ($gid) = fetchrow_array $get1 ) {
            ok( $gid, $id );

        } else {
            ok("no row", $id);
        }
        finish $get1;
    }

    for my $id (7, 8, 9) {
        execute $get2( $id ) or die $dbo->errstr;
        if( my ($oid, $gid) = fetchrow_array $get2 ) {
            ok( $oid, 2*$id );

        } else {
            ok("no row", 2*$id);
        }
        finish $get2;
    }

    for my $id (7, 8, 9) {
        execute $get2( $id ) or die $dbo->errstr;
        if( my $h = fetchrow_hashref $get2 ) {
            ok( $h->{id}, $id );

        } else {
            ok("no row", $id);
        }

        finish $get2;
    }

    $dbo->do("drop table if exists easy_test");

} else {
    plan tests => 1;
    ok(1);
}
