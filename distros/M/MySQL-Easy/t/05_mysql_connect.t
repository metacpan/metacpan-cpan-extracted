
use strict;
use Test;
use Cwd;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 5;

} else {
     plan tests => 1;
}

use MySQL::Easy; ok 1;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    # no good without the tables set up...
    my $dbo = new MySQL::Easy("stocks"); $dbo->set_user("jettero");
    ok $dbo; # 2
    my $show = $dbo->ready("show tables");
    ok $show; # 3

    my $h = $dbo->selectall_hashref( $show, "Tables_in_stocks" );
    ok( ref $h, "HASH");

    print STDERR " ", join(", ", keys %$h), "\n";

    my ($table, $x) = (undef, 0);
    $h = $dbo->bind_execute("show tables", \( $table ));
    die " ... " . $dbo->errstr unless $h;
    while( fetch $h ) {
        $x ++;
    }

    ok $x > 1;
}
