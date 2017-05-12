
use strict;
use warnings;

BEGIN {
    eval "use LWP";
    if ( $@ ) {
	print "1..0 # no LWP\n";
	exit
    }
}

use Net::SSLGlue::LWP;
use IO::Socket::SSL;
use LWP::Simple;

my $goodhost = 'google.de';
my $badhost = 'badcert.maulwuff.de';

my $capath = '/etc/ssl/certs/'; # unix?
-d $capath or do {
    print "1..0 # cannot find system CA-path\n";
    exit
};
Net::SSLGlue::LWP->import( 
    SSL_ca_path => $capath, 
    # LWP might define SSL_ca_file - remove it to avoid conflict
    SSL_ca_file => undef 
);

#
# first check everything directly with IO::Socket::SSL
#

diag("connecting to $goodhost:443 with IO::Socket::INET");
my $sock = IO::Socket::INET->new(
    PeerAddr => "$goodhost:443",
    Timeout => 10
) or do {
    print "1..0 # connect $goodhost failed: $!\n";
    exit
};
diag("ssl upgrade $goodhost");
IO::Socket::SSL->start_SSL( $sock,
    SSL_ca_path => $capath,
    SSL_verifycn_name => "$goodhost",
    SSL_verify_mode => 1,
    SSL_verifycn_scheme => 'http',
) or do {
    print "1..0 # ssl upgrade $goodhost failed: $SSL_ERROR\n";
    exit
};

diag("connecting to $badhost:443 with IO::Socket::INET");
if ( $sock = IO::Socket::INET->new( 
    PeerAddr => "$badhost:443",
    Timeout => 10,
)) {
    diag("upgrading to https - should fail because of bad certificate");
    if ( IO::Socket::SSL->start_SSL( $sock,
	SSL_ca_path => $capath,
	SSL_verify_mode => 1,
	SSL_verifycn_scheme => 'http',
	SSL_verifycn_name => $badhost,
    )) {
	diag("certificate for  $badhost unexpectly correct");
	$badhost = undef;
    };
} else {
    diag("connect to $badhost failed: $!");
    $badhost = undef;
}

#
# and than check, that LWP uses the same checks
#

print "1..".( $badhost ? 3:1 )."\n";

# $goodhost -> should succeed
diag("connecting to $goodhost:443 with LWP");
my $content = get( "https://$goodhost" );
print $content ? "ok\n": "not ok # lwp connect $goodhost: $@\n";

if ( $badhost ) {
    # $badhost -> should fail
    diag("connecting to $badhost:443 with LWP");
    $content = get( "https://$badhost" );
    print $content ? "not ok # lwp ssl connect $badhost should fail\n": "ok\n";

    # $badhost -> should succeed if verify mode is 0
    {
	local %Net::SSLGlue::LWP::SSLopts = %Net::SSLGlue::LWP::SSLopts;
	$Net::SSLGlue::LWP::SSLopts{SSL_verify_mode} = 0;
	$content = get( "https://$badhost" );
	print $content ? "ok\n": "not ok # lwp ssl $badhost w/o ssl verify\n";
    }
}

sub diag { print "# @_\n" }
