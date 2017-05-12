
use strict;
use Test;
use Cwd;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 2;

} else {
    plan tests => 1;
}

use MySQL::Easy; ok 1;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    my $dbo = new MySQL::Easy("scratch");

    eval { $dbo->do("syntax error!!") };
    #arn " \e[1;33m<<$@>>\e[m\n";
    ok( $@, qr(error in your SQL syntax) );
}
