package t::lib::FakeResponse;

# ABSTRACT: A helper that composes a fake responses

use strict;
use HTTP::Response;
use HTTP::Date;

sub compose {
    my (undef, $code, $body) = @_;

    HTTP::Response->new(
        $code,
        undef,
        [
            Date            => time2str(),
            Server          => 'Apache/2.2.25 (FreeBSD) PHP/5.4.17 mod_ssl/2.2.25 OpenSSL/1.0.1e',
            Connection      => 'close',
            Cache_Control   => 'no-cache, no-store',
            Content_Type    => 'application/json; charset=utf-8',
            Content_Length  => length($body),
        ],
        $body,
    );
}

1; # End of t::lib::FakeResponse

__END__
