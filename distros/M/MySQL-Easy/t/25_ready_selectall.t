
use strict;
use Test;
use Cwd;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    use strict;
    use MySQL::Easy;

    plan tests => 3;

    my $dbo = new MySQL::Easy("scratch");

    $dbo->do("drop table if exists easy_test");
    $dbo->do('create table easy_test( id int unsigned not null auto_increment primary key )');

    my $put = $dbo->ready("insert into easy_test set id=?");
    $put->execute( 7 ) or die $dbo->errstr;

    ALL1: {
        my $all = $dbo->firstcol("select id from easy_test");
        ok( $all->[0], 7 );
    }

    ALL2: {
        my $get = $dbo->ready("select id from easy_test");
        my $all = $dbo->selectall_arrayref($get->{sth});
        ok( $all->[0][0], 7 );
    }

    ALL3: {
        my $get = $dbo->ready("select id from easy_test");
        my $all = $dbo->selectall_arrayref($get);
        ok( $all->[0][0], 7 );
    }

} else {
    plan tests => 1;
    ok(1);
}
