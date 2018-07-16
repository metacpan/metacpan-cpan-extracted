use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Net::Whois::IANA;

my $iana = Net::Whois::IANA->new;

my %tests = (
    '200.16.98.2'     => 'AR',
    '200.77.236.16'   => 'MX',
    '200.189.169.141' => 'BR',
);

foreach my $ip ( sort keys %tests ) {
    $iana->whois_query( -ip => $ip, -whois => 'lacnic' );
    ok defined $iana, "IANA for IP $ip";

    if ( defined $iana->country() ) {
        is $iana->country(), $tests{$ip}, "Country is '$tests{$ip}' for IP $ip";
    }
    else {
        diag "no country for IP $ip, expected '$tests{$ip}'\n", explain $iana;
    }

}

done_testing;
