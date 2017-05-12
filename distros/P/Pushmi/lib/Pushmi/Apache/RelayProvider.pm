package Pushmi::Apache::RelayProvider;

use Apache2::RequestUtil ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);

my $memd;
my $logger;

sub handler {
    my ( $r, $user, $password ) = @_;
    my $method = $r->method;

    unless ($memd) {
        my $config = $r->dir_config('PushmiConfig');
        $ENV{PUSHMI_CONFIG} = $config;
        require Pushmi::Config;

        $memd = Pushmi::Config->memcached;
    }

    if ( $method eq 'MKACTIVITY' ) {    # only tryauth on mkactivity
        my $pushmi    = $r->dir_config('Pushmi');
        my $repospath = $r->dir_config('SVNPath');
        my $config    = $r->dir_config('PushmiConfig');

        $ENV{PUSHMI_CONFIG} = $config;

        # XXX: use stdin or setproctitle
        # XXX: log $!
        system(   "$pushmi tryauth $repospath '"
                . $r->user
                . "' '$password'" );

	$memd->set( $r->user, $password, 30 ) unless $?;
	return Apache2::Const::OK unless $?;

	$r->note_basic_auth_failure;
	return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    # refresh
    $memd->set( $r->user, $password, 30 );
    # assuming user is already authenticated after mkactivity
    return Apache2::Const::OK;
}

1;
