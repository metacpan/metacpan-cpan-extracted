#!perl -T

use Test::More tests => 8;

use Net::Squid::Auth::Plugin::SimpleLDAP;

sub check_failure {
    my $p = shift;
    eval { Net::Squid::Auth::Plugin::SimpleLDAP->new($p) };
    ok($@);
}

check_failure();
check_failure('yabadabadoo');
check_failure( ['yabadabadoo'] );
check_failure( {} );
check_failure( { binddn => 1, bindpw => 2, basedn => 3 } );
check_failure( { binddn => 1, bindpw => 2, server => 4 } );
check_failure( { binddn => 1, basedn => 3, server => 4 } );
check_failure( { bindpw => 2, basedn => 3, server => 4 } );
