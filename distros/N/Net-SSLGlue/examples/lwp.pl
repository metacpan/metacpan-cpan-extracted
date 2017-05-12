use strict;
use LWP::UserAgent;
use Net::SSLGlue::LWP SSL_ca_path => '/etc/ssl/certs';

my $ua = LWP::UserAgent->new;
$ua->env_proxy;
my $resp = $ua->get( 'https://www.comdirect.de' ) || die $@;
print $resp->content;
