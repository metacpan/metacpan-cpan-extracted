
use strict;
use Test;
use MySQL::Easy;
use Cwd;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 2;

    my $dbo = new MySQL::Easy("scratch");

    my $bad = $dbo->ready("insert into testy_table set enumer ='not good!'");
    my $oki = $dbo->ready("insert into testy_table set enumer ='good'");

    $dbo->do("create temporary table testy_table( enumer enum('good', 'ugly', 'potato', 'OMFGLMAOBBQ') )");

    execute $bad or die $dbo->errstr;
    unless( check_warnings $dbo )        # example real-call: check_warnings $dbo or die $@ 
         { ok( $@ =~ m/truncated/ ) } 
    else { ok( 0 ) }

    execute $oki or die $dbo->errstr;
    ok( check_warnings $dbo );

} else {
    plan tests => 1;
    ok(1);
}
