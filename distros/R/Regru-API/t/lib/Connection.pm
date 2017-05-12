package t::lib::Connection;

# ABSTRACT: A helper that checks connection to API endpoint

use strict;
use Net::Ping;
use URI;

sub check {
    my (undef, $endpoint) = @_;

    Net::Ping->new->ping(URI->new($endpoint)->host, 1) ? 1 : 0;
}

1; # End of t::lib::Connection

__END__
