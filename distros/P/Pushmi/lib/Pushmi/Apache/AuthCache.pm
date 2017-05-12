package Pushmi::Apache::AuthCache;

use strict;
use warnings;

use Apache2::Access ();
use Apache2::RequestUtil ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(FORBIDDEN OK HTTP_UNAUTHORIZED DECLINED);

my $logger;
my $memd;

sub handler {
    my $r      = shift;
    my $method = $r->method;
    unless ($memd) {
        my $config = $r->dir_config('PushmiConfig');
        $ENV{PUSHMI_CONFIG} = $config;
        require Pushmi::Config;

        $memd = Pushmi::Config->memcached;
	$logger = Pushmi::Config->logger('pushmi.authcache');
    }

    my ( $status, $password ) = $r->get_basic_auth_pw;
    return $status unless $status == Apache2::Const::OK;

    $logger->debug("cache authn information for ".$r->user);

    $memd->set($r->user, $password, 30);

    return Apache2::Const::DECLINED;
}

1;
