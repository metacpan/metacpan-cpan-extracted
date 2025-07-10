package Net::RDAP;
use Digest::SHA qw(sha256_hex);
use File::Slurp;
use File::stat;
use File::Spec;
use HTTP::Request::Common;
use JSON;
use MIME::Base64;
use Net::ASN;
use Net::RDAP::Error;
use Net::RDAP::Help;
use Net::RDAP::Object::Autnum;
use Net::RDAP::Object::Domain;
use Net::RDAP::Object::Entity;
use Net::RDAP::Object::IPNetwork;
use Net::RDAP::Object::Nameserver;
use Net::RDAP::Redaction;
use Net::RDAP::Registry;
use Net::RDAP::SearchResult;
use Net::RDAP::Service;
use Net::RDAP::Values;
use Net::RDAP::JCard;
use POSIX qw(getpwuid);
use vars qw($VERSION);
use constant {
    DEFAULT_CACHE_TTL       => 3600,
    DEFAULT_ACCEPT_LANGUAGE => "en",
};
use strict;
use warnings;

$VERSION = '0.40';

=pod

=encoding UTF-8

=head1 NAME

L<Net::RDAP> - an interface to the Registration Data Access Protocol (RDAP).

=head1 SYNOPSIS

    use Net::RDAP;

    my $rdap = Net::RDAP->new;

    #
    # traditional lookup:
    #

    # get domain info:
    $object = $rdap->domain('example.com');

    # get info about IP addresses/ranges:
    $object = $rdap->ip('192.168.0.1');
    $object = $rdap->ip('2001:DB8::/32');

    # get info about AS numbers:
    $object = $rdap->autnum(65536);

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

RDAP is replacing Whois as the preferred way of obtainining information
about Internet resources (IP addresses, autonymous system numbers, and
domain names). As of writing, RDAP is fully supported by Regional
Internet Registries (who are responsible for the allocation of IP
addresses and AS numbers) and generic TLD operators (e.g. .com, .org,
.xyz) but is still being rolled out among country-code registries.

L<Net::RDAP> does all the hard work of determining the correct
server to query (L<Net::RDAP::Registry> is an interface to the
IANA registry of RDAP services), querying the server (L<Net::RDAP::UA>
is an RDAP HTTP user agent), and parsing the response
(L<Net::RDAP::Object> and its submodules provide access to the data
returned by the server). As such, it provides a single unified
interface to information about all unique Internet identifiers.

If you want a command-line RDAP client, see L<App::rdapper>.

=head1 METHODS

=head2 Constructor

    $rdap = Net::RDAP->new(%OPTIONS);

Constructor method, returns a new object. C<%OPTIONS> is optional, but
may contain any of the following options:

=over

=item * C<use_cache> - if set to a true value, copies of RDAP responses are
stored on disk, and are updated if the copy on the server is more up-to-date.
This behaviour is disabled by default and must be explicitly enabled.
B<Note:> this setting controls whether L<Net::RDAP> caches RDAP records;
it doesn't control caching of IANA registries by L<Net::RDAP::Registry>
and L<Net::RDAP::Values>.

=item * C<cache_ttl> - if set, specifies how long after a record has
been cached before L<Net::RDAP> asks the server for any update. By
default this is one hour (3600 seconds).

=item * C<accept_language> - a string that will be passed to RDAP servers in
the C<Accept-Language> header. If not provided, the default is "C<en>".

=back

=cut

sub new {
    my ($package, %options) = @_;

    return bless(\%options, $package);
}

=pod

=head2 Domain Lookup

    $object = $rdap->domain($domain);

This method returns a L<Net::RDAP::Object::Domain> object containing
information about the domain name referenced by C<$domain>.

C<$domain> must be either a string or a L<Net::DNS::Domain> object containing a
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

    my $domain = $rdap->domain(idn_to_ascii($name, 'UTF-8'));

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

C<$ip> must be either a string or a L<Net::IP> object, and can represent any
of the following:

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

C<$autnum> must be a a literal integer AS number or a L<Net::ASN> object.

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
per L<RFC 8521|https://www.rfc-editor.org/rfc/rfc8521.html>.

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

=head2 Determining object existence

    $exists = $rdap->exists($object);

This method returns a boolean indicating whether C<$object> (which
must be a L<Net::DNS::Domain>, L<Net::IP> or L<Net::ASN>) exists. This
is determined by performing an HTTP C<HEAD> request and inspecting the
resulting HTTP status code.

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
            'errorCode' => 400,
            'title'     => "Unable to deal with '$arg'",
        );
    }

    #
    # add Authorization header field if we have a username/password
    #
    if ($args{'user'} && $args{'pass'}) {
        $self->ua->default_header('Authorization' => 'Basic '.encode_base64($args{'user'}.':'.$args{'pass'}));

    } else {
        $self->ua->default_headers->remove_header('Authorization');

    }

    if (exists($args{'method'}) && 'HEAD' eq $args{'method'}) {
        return $self->_head($url);

    } else {
        return $self->_get($url, %args);

    }
}

sub _head {
    my ($self, $url) = @_;

    my $response = $self->request(HEAD($url));

    if (404 == $response->code) {
        return undef;

    } elsif (200 == $response->code) {
        return 1;

    } else {
        return $self->error(
            'url'           => $url,
            'errorCode'     => $response->code,
            'title'         => $response->status_line,
            'description'   => [$response->status_line],
        );
    }
}

sub _get {
    my ($self, $url, %args) = @_;

    #
    # this is how long we allow things to be cached before checking
    # if they have been updated:
    #
    my $ttl = $self->{'use_cache'} ? ($self->{'cache_ttl'} || DEFAULT_CACHE_TTL) : 0;

    my $lang = $self->{accept_language} || DEFAULT_ACCEPT_LANGUAGE;

    #
    # path to local copy of the remote resource
    #
    my $file = File::Spec->catfile(
        File::Spec->tmpdir,
        sprintf(
            '%s-%s.json',
            ref($self),
            sha256_hex(join(chr(0), (
                $VERSION,
                $url->as_string,
                $lang,
                getpwuid($<),
            )))
        )
    );

    #
    # untaint file
    #
    if ($file =~ /(.+)/) {
        $file = $1;
    }

    my $response = $self->ua->mirror($url, $file, $ttl, $lang);

    my $data = eval { decode_json(scalar(read_file($file))) };

    if ($response->code >= 400) {
        return $self->error_from_response($url, $response, $data);

    } elsif ($data) {
        return $self->rdap_from_response($url, $response, $data, %args);

    } else {
        unlink($file) if (-e $file);

        return $self->error(
            url         => $url,
            errorCode   => 500,
            title       => 'JSON parse error',
        );
    }
}

sub rdap_from_response {
    my ($self, $url, $response, $data, %args) = @_;

    if ($response->is_error) {
        return $self->error_from_response($url, $response, $data);

    } elsif ('HASH' ne ref($data)) {
        #
        # response was not parseable as JSON:
        #
        return $self->error(
            'url'           => $url,
            'errorCode'     => 500,
            'title'         => 'Error parsing response body',
            'description'   => [ 'The response from the server is not a valid JSON object' ],
        );

    } else {
        $data->{'objectClassName'} = $args{'class_override'} if ($args{'class_override'});

        if (!defined($data->{'objectClassName'}) && scalar(grep { /^(domain|nameserver|entity)SearchResults$/ } keys(%{$data})) < 1) {
            #
            # response is missing the objectClassName property and is not a
            # search result:
            #
            return $self->error(
                'url'           => $url,
                'errorCode'     => 500,
                'title'         => "Missing 'objectClassName' property",
                'description'   => [ "The response from the server is missing the 'objectClassName' property" ],
            );

        } else {
            #
            # return object
            #
            return $self->object_from_response($data, $url);
        }
    }
}

sub error_from_response {
    my ($self, $url, $response, $data) = @_;

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
            'url'           => $url,
            'errorCode'     => $response->code,
            'title'         => $response->status_line,
            'description'   => [$response->status_line],
        );
    }
}

#
# generate an RDAP object from an RDAP response
#
sub object_from_response {
    my ($self, $data, $url) = @_;

    if (exists($data->{'objectClassName'})) {
        #
        # lookup results
        #
        if    ('domain'     eq $data->{'objectClassName'})  { return Net::RDAP::Object::Domain->new($data,     $url) }
        elsif ('ip network' eq $data->{'objectClassName'})  { return Net::RDAP::Object::IPNetwork->new($data,  $url) }
        elsif ('autnum'     eq $data->{'objectClassName'})  { return Net::RDAP::Object::Autnum->new($data,     $url) }
        elsif ('nameserver' eq $data->{'objectClassName'})  { return Net::RDAP::Object::Nameserver->new($data, $url) }
        elsif ('entity'     eq $data->{'objectClassName'})  { return Net::RDAP::Object::Entity->new($data,     $url) }

        #
        # 'help' is not a real object type, but Net::RDAP::Service uses the
        # 'class_override' option to fetch() to ensure we return the right
        # object type here
        #
        elsif ('help'       eq $data->{'objectClassName'})  { return Net::RDAP::Help->new($data, $url) }
    }

    #
    # search results
    #
    elsif (exists($data->{'domainSearchResults'}))      { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (exists($data->{'nameserverSearchResults'}))  { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (exists($data->{'entitySearchResults'}))      { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (exists($data->{'ipSearchResults'}))          { return Net::RDAP::SearchResult->new($data, $url) }
    elsif (exists($data->{'autnumSearchResults'}))      { return Net::RDAP::SearchResult->new($data, $url) }

    #
    # unprocessable response
    #
    else {
        my $msg = "Unknown objectClassName '$data->{'objectClassName'}'";
        return $self->error(
            'url'           => $url,
            'errorCode'     => 500,
            'title'         => $msg,
            'description'   => [ $msg ],
        );
    }
}

#
# a simple check that a server response is indeed an RDAP response
#
sub is_rdap {
    my ($self, $response) = @_;

    return (
        !$response->base ||
        'file' eq $response->base->scheme
    ) ||
    (
        $response->header('content-type') &&
        $response->header('content-type') =~ /^application\/(rdap\+|)json/
    );
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

    my $svc = Net::RDAP::Service->new('https://www.example.com/rdap');

    # $result is a Net::RDAP::SearchResult
    my $result = $svc->domains('name' => 'ex*mple.com');

RDAP supports a limited search capability, but you need to know in advance which
RDAP server you want to send the search query to.

The L<Net::RDAP::Service> class allows you to prepare and submit search queries
to specific RDAP servers. For more information, please see the documentation for
that module.

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
    # inject our UA object into NET::RDAP::Registry and NET::RDAP::Values so
    # everything uses the same user agent
    #
    $NET::RDAP::Registry::UA = $NET::RDAP::Registry::Values = $self->{'ua'};

    return $self->{'ua'};
}

#
# construct an error. arguments: errorCode, title, description
#
sub error {
    my ($self, %params) = @_;
    return Net::RDAP::Error->new(
        {
            'errorCode'     => $params{'errorCode'},
            'title'         => $params{'title'},
            'description'   => $params{'description'},
        },
        $params{'url'},
    );
}

1;

__END__

=pod

=head1 HOW TO CONTRIBUTE

L<Net::RDAP> is a work-in-progress; if you would like to help, the
project is hosted here:

=over

=item * L<https://github.com/gbxyz/perl-net-rdap>

=back

=head1 DISTRIBUTION

The L<Net::RDAP> CPAN distribution contains a large number of
RDAP-related modules that all work together. They are:

=over

=item * L<Net::RDAP::Base>

=over

=item * L<Net::RDAP::Event>

=item * L<Net::RDAP::ID>

=item * L<Net::RDAP::Object>

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

=item * L<Net::RDAP::Remark>

=over

=item * L<Net::RDAP::Notice>

=back

=back

=item * L<Net::RDAP::EPPStatusMap>

=item * L<Net::RDAP::JCard>

=over

=item * L<Net::RDAP::JCard::Property>

=item * L<Net::RDAP::JCard::Address>

=back

=item * L<Net::RDAP::Registry>

=item * L<Net::RDAP::Registry::IANARegistry>

=item * L<Net::RDAP::Registry::IANARegistry::Service>

=item * L<Net::RDAP::Service>

=item * L<Net::RDAP::Link>

=item * L<Net::RDAP::UA>

=item * L<Net::RDAP::Values>

=item * L<Net::RDAP::Variant>

=item * L<Net::RDAP::VariantName>

=back

=head1 REFERENCES

=over

=item * L<https://tools.ietf.org/html/rfc7480> - HTTP Usage in the Registration
Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc7481> - Security Services for the
Registration Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc9082> - Registration Data Access
Protocol (RDAP) Query Format

=item * L<https://tools.ietf.org/html/rfc9083> - JSON Responses for the
Registration Data Access Protocol (RDAP)

=item * L<https://tools.ietf.org/html/rfc9224> - Finding the Authoritative
Registration Data (RDAP) Service

=item * L<https://tools.ietf.org/html/rfc8056> - Extensible Provisioning
Protocol (EPP) and Registration Data Access Protocol (RDAP) Status Mapping

=item * L<https://tools.ietf.org/html/rfc8288> -  Web Linking

=item * L<https://tools.ietf.org/html/rfc8521> -  Registration Data Access
Protocol (RDAP) Object Tagging

=item * L<https://tools.ietf.org/html/rfc9536> -  Registration Data Access
Protocol (RDAP) Reverse Search

=item * L<https://tools.ietf.org/html/rfc9537> -  Redacted Fields in the
Registration Data Access Protocol (RDAP) Response

=back

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut
