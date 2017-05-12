
use strict;
use utf8;
use Test;
use Cwd;
use DBI qw(:utils);

use DBD::mysql;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    use strict;
    use MySQL::Easy;

    my @values = (
        "Váfuðr",
        "Váfuðr—",
        "Váfuðr — ☥",
        "ポル — über ☥"
        );

    plan tests => 3*@values;

    my $dbo = new MySQL::Easy("scratch");

    $dbo->do("drop table if exists easy_test");
    $dbo->do('create table easy_test( id int unsigned not null primary key, testfield varchar(255) character set utf8 not null )');

    my $test = 1;
    for my $test_value(@values) {
        ok( data_string_desc($test_value), qr(UTF8 on) );

        my $put = $dbo->ready("replace into easy_test set id=?, testfield=?");
        my $get = $dbo->ready("select testfield from easy_test where id=?");

        $put->execute($test, $test_value);
        $get->execute($test);
        $get->bind_columns(\my $val);
        $get->fetch;

        ok( data_string_desc($val), qr(UTF8 on) );
        ok( $val, $test_value );

        $test++;
    }


} else {
    plan tests => 1;
    ok(1);
}
