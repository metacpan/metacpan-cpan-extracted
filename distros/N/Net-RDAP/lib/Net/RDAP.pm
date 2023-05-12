package Net::RDAP;
use Digest::SHA1 qw(sha1_hex);
use File::Slurp;
use File::stat;
use HTTP::Request::Common;
use JSON;
use MIME::Base64;
use Net::RDAP::Error;
use Net::RDAP::Help;
use Net::RDAP::Object::Autnum;
use Net::RDAP::Object::Domain;
use Net::RDAP::Object::Entity;
use Net::RDAP::Object::IPNetwork;
use Net::RDAP::Object::Nameserver;
use Net::RDAP::Registry;
use Net::RDAP::SearchResult;
use Net::RDAP::Service;
use vars qw($VERSION);
use strict;

$VERSION = 0.18;

=pod

=encoding UTF-8

=head1 NAME

L<Net::RDAP> - an interface to the Registration Data Access Protocol
(RDAP).

=head1 SYNOPSIS

    use Net::RDAP;

    my $rdap = Net::RDAP->new;

    #
    # traditional lookup:
    #

    # get domain info:
    $object = $rdap->domain(Net::DNS::Domain->new('example.com'));

    # get info about IP addresses/ranges:
    $object = $rdap->ip(Net::IP->new('192.168.0.1'));
    $object = $rdap->ip(Net::IP->new('2001:DB8::/32'));

    # get info about AS numbers:
    $object = $rdap->autnum(Net::ASN->new(65536));

    #
    # search functions:
    #

    my $server = Net::RDAP::Service->new("https://www.example.com/rdap");

    # search for domains by name:
    my $result = $server->domains('name' => 'ex*mple.com');

    # search for entities by name:
    my $result = $server->entities('fn' => 'J*n Doe');

    # search for nameservers by IP address:
    my $result = $server->nameservers('ip' => '192.168.56.101');

=head1 DESCRIPTION

L<Net::RDAP> provides an interface to the Registration Data Access
Protocol (RDAP).

RDAP is gradually replacing Whois as the preferred way of obtainining
information about Internet resources (IP addresses, autonymous system
numbers, and domain names). As of writing, RDAP is quite well-supported
by Regional Internet Registries (who are responsible for the allocation
of IP addresses and AS numbers) but is still being rolled out among
domain name registries and registrars.

L<Net::RDAP> does all the hard work of determining the correct
server to query (L<Net::RDAP::Registry> is an interface to the
IANA registry of RDAP services), querying the server (L<Net::RDAP::UA>
is an RDAP HTTP user agent), and parsing the response
(L<Net::RDAP::Object> and its submodules provide access to the data
returned by the server). As such, it provides a single unified
interface to information about all unique Internet identifiers.

=head1 METHODS

=head2 Constructor

    $rdap = Net::RDAP->new(%OPTIONS);

Constructor method, returns a new object. %OPTIONS is optional, but
may contain any of the following options:

=over

=item * C<use_cache> - if true, copies of RDAP responses are stored on
disk, and are updated if the copy on the server is more up-to-date.
This behaviour is disabled by default and must be explicitly enabled.

=item * C<debug> - if true, tells L<Net::RDAP::UA> to print all HTTP
requests and responses to C<STDERR>.

=back

=cut

sub new {
    my ($package, %options) = @_;

    my $self = bless(\%options, $package);

    $Net::RDAP::UA::DEBUG = $self->{'debug'};

    return $self;
}

=pod

=head2 Domain Lookup

    $object = $rdap->domain($domain);

This method returns a L<Net::RDAP::Object::Domain> object containing
information about the domain name referenced by C<$domain>.

C<$domain> must be a L<Net::DNS::Domain> object or a string containing a
fully-qualified domain name. The domain may be either a "forward" domain
(such as C<example.com>) or a "reverse" domain (such as C<168.192.in-addr.arpa>).

If there was an error, this method will return a L<Net::RDAP::Error>.

=head3 Note on Internationalised Domain Names (IDNs)

Domain names which contain characters other than those from the ASCII-compatible
range must be encoded into "A-label" (or "Punycode") format before being passed
to L<Net::DNS::Domain>. You can use L<Net::LibIDN> or L<Net::LibIDN2> to
perform this encoding:

    use Net::LibIDN;

    my $name = "espécime.com";

    my $domain = $rdap->domain->(Net::DNS::Domain->new(idn_to_ascii($name, 'UTF-8')));

=cut

sub domain {
    my ($self, $object, %args) = @_;

    if ('Net::DNS::Domain' ne ref($object)) {
        return $self->query('object' => Net::DNS::Domain->new($object), %args);

    } else {
        return $self->query('object' => $object, %args);

    }
}

=pod

=head2 IP Lookup

    $object = $rdap->ip($ip);

This method returns a L<Net::RDAP::Object::IPNetwork> object containing
information about the resource referenced by C<$ip>.

C<$ip> must be either a L<Net::IP> object or a string, and can represent any of the
following:

=over

=item * An IPv4 address (e.g. C<192.168.0.1>);

=item * An IPv4 CIDR range (e.g. C<192.168.0.1/16>);

=item * An IPv6 address (e.g. C<2001:DB8::42:1>);

=item * An IPv6 CIDR range (e.g. C<2001:DB8::/32>).

=back

If there was an error, this method will return a L<Net::RDAP::Error>.

=cut

sub ip {
    my ($self, $object, %args) = @_;

    if ('Net::IP' ne ref($object)) {
        return $self->query('object' => Net::IP->new($object), %args);

    } else {
        return $self->query('object' => $object, %args);

    }
}

=pod

=head2 AS Number Lookup

    $object = $rdap->autnum($autnum);

This method returns a L<Net::RDAP::Object::Autnum> object containing
information about the autonymous system referenced by C<$autnum>.

C<$autnum> must be a L<Net::ASN> object or an literal integer AS number.

If there was an error, this method will return a L<Net::RDAP::Error>.

=cut

sub autnum {
    my ($self, $object, %args) = @_;

    if ('Net::ASN' ne ref($object)) {
        return $self->query('object' => Net::ASN->new($object), %args);

    } else {
        return $self->query('object' => $object, %args);

    }
}

=pod

=head2 Entity Lookup

    $entity = $rdap->entity($handle);

This method returns a L<Net::RDAP::Object::Entity> object containing
information about the entity referenced by C<$handle>, which must be
a string containing a "tagged" handle, such as C<ABC123-EXAMPLE>, as
per RFC 8521.

=cut

sub entity {
    my ($self, $object, %args) = @_;

    if ($object !~ /-/) {
        return $self->error(
            'errorCode'    => 400,
            'title'        => 'argument must be a tagged handle',
        );

    } else {
        return $self->query('object' => $object, %args);

    }
}

#
# main method
#
sub query {
    my ($self, %args) = @_;

    #
    # get the URL from the registry
    #
    my $url = Net::RDAP::Registry->get_url($args{'object'});

    if (!$url) {
        return $self->error(
            'errorCode'    => 400,
            'title'        => 'Unable to obtain URL for object',
        );
        
    } else {
        return $self->fetch($url, %args);

    }
}

=pod

    $exists = $rdap->exists($object);

This method returns a boolean indicating whether C<$object> (which
must be a L<Net::DNS::Domain>, L<Net::IP> or L<Net::ASN>) exists.

B<Note>: the non-existence of an object does not indicate whether that
object is available for registration.

If there was an error, or no RDAP server is available for the specified
object, this method will return a L<Net::RDAP::Error>.

=cut

sub exists {
    my ($self, $object, %args) = @_;
    return $self->query('object' => $object, 'method' => 'HEAD', %args);
}

=pod

=head2 Directly Fetching Known Resources

    $object = $rdap->fetch($thing, %OPTIONS);

This method retrieves the resource identified by C<$thing>, which must
be either a L<URI> or L<Net::RDAP::Link> object, and returns a
L<Net::RDAP::Object> object (assuming that the server returns a valid
RDAP response). This method is used internally by L<Net::RDAP> but is
also available for when you want to directly fetch a resource without
using the IANA registry.

C<%OPTIONS> is an optional hash containing additional options for
the query. The following options are supported:

=over

=item * C<user> and C<pass>: if provided, they will be sent to the
server in an HTTP Basic Authorization header field.

=item * C<class_override>: allows you to set or override the
C<objectClassName> property in RDAP responses.

=back

=cut

sub fetch {
    my ($self, $arg, %args) = @_;

    my $url;
    if ($arg->isa('URI')) {
        $url = $arg;

    } elsif ($arg->isa('Net::RDAP::Link')) {
        $url = $arg->href;

    } else {
        return $self->error(
            'errorCode'        => 400,
            'title'            => "Unable to deal with '$arg'",
        );
    }

    #
    # construct HTTP::Request object
    #
    my ($request, $file);
    if ('HEAD' eq $args{'method'}) {
        $request = HEAD($url);

    } else {
        $request = GET($url);

        #
        # add Authorization header field if we have a username/password
        #
        $request->header('Authorization' => sprintf('Basic %s', encode_base64(join(':', ($args{'user'}, $args{'pass'}))))) if ($args{'user'} && $args{'pass'});

        #
        # path to local copy of the remote resource
        #
        $file = sprintf(
            '%s/Net-RDAP-cache-%s.json',
            ($ENV{'TMPDIR'} || '/tmp'),
            sha1_hex($url->isa('URI') ? $url->as_string : $url),
        );

        #
        # we have a locally-cached copy, so add the If-Modified-Since header field
        #
        $request->header('If-Modified-Since' => HTTP::Date::time2str(stat($file)->mtime)) if (-e $file && $self->{'use_cache'});
    }

    #
    # get the response from the server
    #
    my $response = $self->request($request);

    if ('HEAD' eq $args{'method'}) {
        if (404 == $response->code) {
            return undef;

        } elsif (200 == $response->code) {
            return 1;

        } else {
            return $self->error(
                'url'        => $url,
                'errorCode'    => $response->code,
                'title'        => $response->status_line,
            );
        }

    } else {
        #
        # attempt to parse the JSON. The RDAP server *should* only ever send JSON, but
        # this cannot be guaranteed:
        #
        my $data;
        eval { $data = decode_json($response->decoded_content) };

        #
        # check and parse the response
        #
        if (-e $file && (304 == $response->code || ($response->code >= 500))) {
            #
            # 304 response, or some sort of network/server error, but we have a
            # cached copy:
            #
            utime(undef, undef, $file) if (304 == $response->code);
            return $self->object_from_response(decode_json(read_file($file)), $url);

        } elsif ($response->is_error) {
            #
            # some other error:
            #
            if ($self->is_rdap($response) && defined($data->{'errorCode'})) {
                #
                # we got an RDAP response from the server which looks like
                # it's an error, so convert it and return:
                #
                return Net::RDAP::Error->new($data, $url);

            } else {
                #
                # build our own error
                #
                return $self->error(
                    'url'        => $url,
                    'errorCode'    => $response->code,
                    'title'        => $response->status_line,
                );
            }

        } elsif (!$self->is_rdap($response)) {
            #
            # we got something that isn't a valid RDAP response:
            #
            return $self->error(
                'url'        => $url,
                'errorCode'    => 500,
                'title'        => 'Invalid Content-Type',
                'description'    => [ sprintf("The Content-Type of the header is '%s', should be 'application/rdap+json'", $response->header('Content-Type')) ],
            );

        } elsif (!defined($data) || 'HASH' ne ref($data)) {
            #
            # response was not parseable as JSON:
            #
            return $self->error(
                'url'        => $url,
                'errorCode'    => 500,
                'title'        => 'Error parsing response body',
                'description'    => [ 'The response from the server is not a valid JSON object' ],
            );

        } else {
            $data->{'objectClassName'} = $args{'class_override'} if ($args{'class_override'});

            if (!defined($data->{'objectClassName'}) && scalar(grep { /^(domain|nameserver|entity)SearchResults$/ } keys(%{$data})) < 1) {
                #
                # response is missing the objectClassName property and is not a search result:
                #
                return $self->error(
                    'url'        => $url,
                    'errorCode'    => 500,
                    'title'        => "Missing 'objectClassName' property",
                    'description'    => [ "The response from the server is missing the 'objectClassName' property" ],
                );

            } else {
                #
                # update local cache
                #
                write_file($file, $response->decoded_content) if ($self->{'use_cache'});
                chmod(0600, $file);

                #
                # return object
                #
                return $self->object_from_response($data, $url);
            }
        }
    }
}

#
# generate an RDAP object from an RDAP response
#
sub object_from_response {
    my ($self, $data, $url) = @_;

    #
    # lookup results
    #
    if ('domain'        eq $data->{'objectClassName'})     { return Net::RDAP::Object::Domain->new($data, $url)    }
    elsif ('ip network'    eq $data->{'objectClassName'})    { return Net::RDAP::Object::IPNetwork->new($data, $url)    }
    elsif ('autnum'        eq $data->{'objectClassName'})    { return Net::RDAP::Object::Autnum->new($data, $url)    }
    elsif ('nameserver'    eq $data->{'objectClassName'})    { return Net::RDAP::Object::Nameserver->new($data, $url)}
    elsif ('entity'        eq $data->{'objectClassName'})    { return Net::RDAP::Object::Entity->new($data, $url)    }
    elsif ('help'        eq $data->{'objectClassName'})    { return Net::RDAP::Help->new($data, $url)        }

    #
    # search results
    #
    elsif (defined($data->{'domainSearchResults'}))        { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (defined($data->{'nameserverSearchResults'}))    { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (defined($data->{'entitySearchResults'}))        { return Net::RDAP::SearchResult->new($data, $url) }

    #
    # unprocessable response
    #
    else {
        return $self->error(
            'url'        => $url,
            'errorCode'    => 500,
            'title'        => "Unknown objectClassName '$data->{'objectClassName'}'",
            'description'    => [ "Unknown objectClassName '$data->{'objectClassName'}'" ],
        );
    }
}

#
# simple check that a server response is indeed an RDAP object
#
sub is_rdap {
    my ($self, $response) = @_;

    return ('file' eq $response->base->scheme || ($response->header('Content-Type') =~ /^application\/rdap\+json/ || $response->header('Content-Type') =~ /^application\/json/));
}

#
# wrapper function
#
sub request {
    my ($self, $req) = @_;
    return $self->ua->request($req);
}

=pod

=head2 Performing Searches

RDAP supports a limited search capability, but you need to know in
advance which RDAP server you want to send the search query to. The
L<Net::RDAP::Service> class allows you to prepare and submit search
queries to specific RDAP servers.

=head2 RDAP User Agent

    # access the user agent
    $ua = $rdap->ua;

    # specify a cookie jar
    $rdap->ua->cookie_jar('/tmp/cookies.txt');

    # specify a proxy
    $rdap->ua->proxy([qw(http https)], 'https://proxy.example.com');

You can access the L<Net::RDAP::UA> object used to communicate with RDAP
servers using the C<ua()> method. This allows you to configure additional
HTTP features such as a file to store cookies, proxies, custom user-agent
strings, etc.

=cut

sub ua {
    my $self = shift;
    $self->{'ua'} = Net::RDAP::UA->new if (!defined($self->{'ua'}));

    #
    # inject our UA object into NET::RDAP::Registry so everything
    # uses the same user agent
    #
    $NET::RDAP::Registry::UA = $self->{'ua'} if (!defined($NET::RDAP::Registry::UA));

    return $self->{'ua'};
}

#
# construct an error. arguments: errorCode, title, description
#
sub error {
    my ($self, %params) = @_;
    return Net::RDAP::Error->new(
        {
            'errorCode' => $params{'errorCode'},
            'title'    => $params{'title'},
            'description' => $params{'description'},
        },
        $params{'url'},
    );
}

=pod

=head1 HOW TO CONTRIBUTE

L<Net::RDAP> is a work-in-progress; if you would like to help, the
project is hosted here:

=over

=item * L<https://gitlab.centralnic.com/centralnic/perl-net-rdap>

=back

=head1 DISTRIBUTION

The L<Net::RDAP> CPAN distribution contains a large number of#
RDAP-related modules that all work together. They are:

=over

=item * L<Net::RDAP::Base>, and its submodules:

=over

=item * L<Net::RDAP::Event>

=item * L<Net::RDAP::ID>

=item * L<Net::RDAP::Object>, and its submodules:

=over

=item * L<Net::RDAP::Error>

=item * L<Net::RDAP::Help>

=item * L<Net::RDAP::Object::Autnum>

=item * L<Net::RDAP::Object::Domain>

=item * L<Net::RDAP::Object::Entity>

=item * L<Net::RDAP::Object::IPNetwork>

=item * L<Net::RDAP::Object::Nameserver>

=item * L<Net::RDAP::SearchResult>

=back

=item * L<Net::RDAP::Remark>, and its submodule:

=over

=item * L<Net::RDAP::Notice>

=back

=back

=item * L<Net::RDAP::EPPStatusMap>

=item * L<Net::RDAP::Registry>

=item * L<Net::RDAP::Registry::IANARegistry>

=item * L<Net::RDAP::Registry::IANARegistry::Service>

=item * L<Net::RDAP::Service>

=item * L<Net::RDAP::Link>

=item * L<Net::RDAP::UA>

=item * L<Net::RDAP::Values>

=back

=head1 DEPENDENCIES

=over

=item * L<DateTime::Format::ISO8601>

=item * L<Digest::SHA1>

=item * L<File::Basename>

=item * L<File::Slurp>

=item * L<File::Spec>

=item * L<File::stat>

=item * L<HTTP::Request::Common>

=item * L<JSON>

=item * L<LWP::Protocol::https>

=item * L<LWP::UserAgent>

=item * L<Mozilla::CA>

=item * L<Net::ASN>

=item * L<Net::DNS>

=item * L<Net::IP>

=item * L<URI>

=item * L<vCard>

=item * L<XML::LibXML>

=back

=head1 REFERENCES

=over

=item * L<https://tools.ietf.org/html/rfc7480> - HTTP Usage in the Registration
Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc7481> - Security Services for the
Registration Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc7482> - Registration Data Access
Protocol (RDAP) Query Format

=item * L<https://tools.ietf.org/html/rfc7483> - JSON Responses for the
Registration Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc7484> - Finding the Authoritative
Registration Data (RDAP) Service

=item * L<https://tools.ietf.org/html/rfc8056> - Extensible Provisioning
Protocol (EPP) and Registration Data Access Protocol (RDAP) Status Mapping

=item * L<https://tools.ietf.org/html/rfc8288> -  Web Linking

=item * L<https://tools.ietf.org/html/rfc8521> -  Registration Data Access
Protocol (RDAP) Object Tagging

=back

=head1 COPYRIGHT

Copyright 2022 CentralNic Ltd. All rights reserved.

=head1 LICENSE

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

=cut

1;
