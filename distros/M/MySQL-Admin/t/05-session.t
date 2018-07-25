use strict;
use MySQL::Admin::Session;
use vars qw($session);
*session = \$MySQL::Admin::Session::session;
$session = {
    query => "???Query.pl",
    Query => "./Query.pl"
};
saveSession("./Query.pl");
undef $session;
use Test::More tests => 3;
my $t1 = $session->{query};
ok( not defined $t1 );
loadSession("./Query.pl");
*session = \$MySQL::Admin::Session::session;
$t1      = $session->{query};
my $t2 = $session->{Query};
ok( $t1 eq "???Query.pl" );
ok( $t2 eq "./Query.pl" );
unlink './Query.pl' or warn "Could not unlink Query.pl: $!";
