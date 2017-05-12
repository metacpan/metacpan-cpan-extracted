package Pushmi::Apache::AuthCommit;

use strict;
use warnings;
use Pushmi::Apache::RelayProvider;

use Apache2::Access ();
use Apache2::RequestUtil ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(FORBIDDEN OK HTTP_UNAUTHORIZED DECLINED);

my $memd;

sub handler {
    my $r      = shift;
    my $method = $r->method;

    my ( $status, $password ) = $r->get_basic_auth_pw;
    return $status unless $status == Apache2::Const::OK;

    return Pushmi::Apache::RelayProvider::handler($r, $r->user, $password);
}

1;
