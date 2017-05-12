use strict;
use LWP::UserAgent;
use Net::SSLGlue::LWP SSL_ca_path => '/etc/ssl/certs', SSL_verify_mode => 0;

my $ua = LWP::UserAgent->new;
$ua->env_proxy;
my $resp = $ua->post( 'https://service.gmx.net/de/cgi/login', {
	AREA => 1,
	EXT => 'redirect',
	EXT2 => '',
	uinguserid => '__uuid__',
	dlevel => 'c',
	id => 'a',
	p => 'b',
}) || die $@;
print $resp->as_string;
