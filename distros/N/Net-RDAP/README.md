# NAME

[Net::RDAP](https://metacpan.org/pod/Net::RDAP) - an interface to the Registration Data Access Protocol
(RDAP).

# SYNOPSIS

        use Net::RDAP;

        my $rdap = Net::RDAP->new;

        # get domain info:
        $data = $rdap->domain(Net::DNS::Domain->new('example.com'));

        # get info about IP addresses/ranges:
        $data = $rdap->ip(Net::IP->new('192.168.0.1'));
        $data = $rdap->ip(Net::IP->new('2001:DB8::/32'));

        # get info about AS numbers:
        $data = $rdap->ip(Net::ASN->new(65536));

# DESCRIPTION

[Net::RDAP](https://metacpan.org/pod/Net::RDAP) provides an interface to the Registration Data Access
Protocol (RDAP). RDAP is a replacement for Whois.

[Net::RDAP](https://metacpan.org/pod/Net::RDAP) does all the hard work of determining the correct
server to query ([Net::RDAP::Registry](https://metacpan.org/pod/Net::RDAP::Registry) is an interface to the
IANA registries), querying the sserver ([Net::RDAP::UA](https://metacpan.org/pod/Net::RDAP::UA) is an
RDAP HTTP user agent), and parsing the response
([Net::RDAP::Response](https://metacpan.org/pod/Net::RDAP::Response) provides access to the data returned
by the server).

# METHODS

        $rdap = Net::RDAP->new;

Constructor method, returns a new object.

        $info = $rdap->domain($domain);

This method returns a [Net::RDAP::Response](https://metacpan.org/pod/Net::RDAP::Response) object containing
information about the domain name referenced by `$domain`.
`$domain` must be a [Net::DNS::Domain](https://metacpan.org/pod/Net::DNS::Domain) object.

If no RDAP service can be found, then `undef` is returned.

        $info = $rdap->ip($ip);

This method returns a [Net::RDAP::Response](https://metacpan.org/pod/Net::RDAP::Response) object containing
information about the resource referenced by `$ip`.
`$ip` must be a [Net::IP](https://metacpan.org/pod/Net::IP) object and can represent any of the
following:

- An IPv4 address (e.g. `192.168.0.1`);
- An IPv4 CIDR range (e.g. `192.168.0.1/16`);
- An IPv6 address (e.g. `2001:DB8::42:1`);
- An IPv6 CIDR range (e.g. `2001:DB8::/32`).

If no RDAP service can be found, then `undef` is returned.

        $info = $rdap->autnum($autnum);

This method returns a [Net::RDAP::Response](https://metacpan.org/pod/Net::RDAP::Response) object containing
information about to the autonymous system referenced by `$autnum`.
`$autnum` must be a [Net::ASN](https://metacpan.org/pod/Net::ASN) object.

If no RDAP service can be found, then `undef` is returned.

# COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

# LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
