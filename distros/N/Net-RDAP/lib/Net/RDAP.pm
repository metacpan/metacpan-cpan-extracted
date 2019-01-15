package Net::RDAP;
use Digest::SHA1 qw(sha1_hex);
use File::Slurp;
use File::stat;
use HTTP::Request::Common;
use JSON;
use MIME::Base64;
use Net::RDAP::Error;
use Net::RDAP::Object::Autnum;
use Net::RDAP::Object::Domain;
use Net::RDAP::Object::IPNetwork;
use Net::RDAP::Registry;
use Net::RDAP::SearchResult;
use vars qw($VERSION);
use strict;

$VERSION = 0.13;

=pod

=head1 NAME

L<Net::RDAP> - an interface to the Registration Data Access Protocol
(RDAP).

=head1 SYNOPSIS

	use Net::RDAP;

	my $rdap = Net::RDAP->new;

	# get domain info:
	$object = $rdap->domain(Net::DNS::Domain->new('example.com'));

	# get info about IP addresses/ranges:
	$object = $rdap->ip(Net::IP->new('192.168.0.1'));
	$object = $rdap->ip(Net::IP->new('2001:DB8::/32'));

	# get info about AS numbers:
	$object = $rdap->ip(Net::ASN->new(65536));

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

Constructor method, returns a new object.

Supported options:

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

C<$domain> must be a L<Net::DNS::Domain> object. The domain may be
either a "forward" domain (such as C<example.com>) or a "reverse"
domain (such as C<168.192.in-addr.arpa>).

If there was an error, this method will return a L<Net::RDAP::Error>.

=cut

sub domain {
	my ($self, $object, %args) = @_;

	if ('Net::DNS::Domain' ne ref($object)) {
		return $self->error(
			'errorCode'	=> 400,
			'title'		=> 'argument must be a Net::DNS::Domain',
		);

	} else {
		return $self->query('object' => $object, %args);

	}
}

=pod

=head2 IP Lookup

	$object = $rdap->ip($ip);

This method returns a L<Net::RDAP::Object::IPNetwork> object containing
information about the resource referenced by C<$ip>.

C<$ip> must be a L<Net::IP> object and can represent any of the
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
		return $self->error(
			'errorCode'	=> 400,
			'title'		=> 'argument must be a Net::IP',
		);

	} else {
		return $self->query('object' => $object, %args);

	}
}

=pod

=head2 AS Number Lookup

	$object = $rdap->autnum($autnum);

This method returns a L<Net::RDAP::Object::Autnum> object containing
information about the autonymous system referenced by C<$autnum>.

C<$autnum> must be a L<Net::ASN> object.

If there was an error, this method will return a L<Net::RDAP::Error>.

=cut

sub autnum {
	my ($self, $object, %args) = @_;

	if ('Net::ASN' ne ref($object)) {
		return $self->error(
			'errorCode'	=> 400,
			'title'		=> 'argument must be a Net::ASN',
		);

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
			'errorCode'	=> 400,
			'title'		=> 'argument must be a tagged handle',
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
			'errorCode'	=> 400,
			'title'		=> 'Unable to obtain URL for object',
		);
		
	} else {
		return $self->fetch($url, %args);

	}
}

=pod

=head2 Directly Fetching Known Resources

	$object = $rdap->fetch($url);

	$object = $rdap->fetch($link);

	$object = $rdap->fetch($object);

The first and second forms of the C<fetch()> method retrieve the
resource identified by C<$url> or C<$link> (which must be either a
L<URI> or L<Net::RDAP::Link> object), and return a L<Net::RDAP::Object>
object (assuming that the server returns a valid RDAP response). This
method is used internally by C<query()> but is also available for when
you need to directly fetch a resource without using the IANA
registry, such as for nameserver or untagged entity queries.

The third form allows the method to be called on an existing
L<Net::RDAP::Object>. Objects which are embedded inside other
objects (such as the entities and nameservers which are associated
with a domain name) may be truncated or redacted in some way:
this method form allows you to obtain the full object. Here's an
example:

	$rdap = Net::RDAP->new;

	$domain = $rdap->domain(Net::DNS::Domain->new('example.com'));

	foreach my $ns ($domain->nameservers) {
		# $ns is a "stub" object, containing only the host name and a "self" link

		my $nameserver = $rdap->fetch($ns);

		# $nameserver is now fully populated
	}

In order for this form to work, the object must have a C<self> link:
L<Net::RDAP> will auto-create one for objects that don't have one if it
can.

=cut

sub fetch {
	my ($self, $arg, %args) = @_;

	my $url;
	if ($arg->isa('URI')) {
		$url = $arg;

	} elsif ($arg->isa('Net::RDAP::Link')) {
		$url = $arg->href;

	} elsif ($arg->isa('Net::RDAP::Object')) {
		my $link = $arg->self;
		if (!$link) {
			return $self->error(
				'errorCode'	=> 400,
				'title'		=> "Object does not have a 'self' link",
			);

		} else {
			$url = $link->href;

		}

	} else {
		return $self->error(
			'errorCode'		=> 400,
			'title'			=> "Unable to deal with '$arg'",
		);
	}

	my $request = GET($url);

	$request->header('Authorization' => sprintf('Basic %s', encode_base64(join(':', ($args{'user'}, $args{'pass'}))))) if ($args{'user'} && $args{'pass'});

	my $file = sprintf(
		'%s/Net-RDAP-cache-%s.json',
		($ENV{'TMPDIR'} || '/tmp'),
		sha1_hex($url),
	);

	$request->header('If-Modified-Since' => HTTP::Date::time2str(stat($file)->mtime)) if (-e $file && $self->{'use_cache'});

	#
	# get the response from the server
	#
	my $response = $self->request($request);

	#
	# attempt to parse the JSON
	#
	my $data;
	eval { $data = decode_json($response->decoded_content) };

	#
	# check and parse the response
	#
	if (-e $file && (304 == $response->code || ($response->code >= 500))) {
		utime(undef, undef, $file) if (304 == $response->code);
		return $self->object_from_response(decode_json(read_file($file)), $url);

	} elsif ($response->is_error) {
		if ($self->is_rdap($response) && defined($data->{'errorCode'})) {
			#
			# we got an RDAP response from the server which looks like it's an error, so convert it and return
			#
			return Net::RDAP::Error->new($data, $url);

		} else {
			#
			# build our own error
			#
			return $self->error(
				'url'		=> $url,
				'errorCode'	=> $response->code,
				'title'		=> $response->status_line,
			);
		}

	} elsif (!$self->is_rdap($response)) {
		return $self->error(
			'url'		=> $url,
			'errorCode'	=> 500,
			'title'		=> 'Invalid Content-Type',
			'description'	=> [ sprintf("The Content-Type of the header is '%s', should be 'application/rdap+json'", $response->header('Content-Type')) ],
		);

	} elsif (!defined($data) || 'HASH' ne ref($data)) {
		return $self->error(
			'url'		=> $url,
			'errorCode'	=> 500,
			'title'		=> 'Error parsing response body',
			'description'	=> [ 'The response from the server is not a valid JSON object' ],
		);

	} elsif (!defined($data->{'objectClassName'}) && scalar(grep { /^(domain|nameserver|entity)SearchResults$/ } keys(%{$data})) < 1) {
		return $self->error(
			'url'		=> $url,
			'errorCode'	=> 500,
			'title'		=> "Missing 'objectClassName' property",
			'description'	=> [ "The response from the server is missing the 'objectClassName' property" ],
		);

	} else {
		write_file($file, $response->decoded_content) if ($self->{'use_cache'});
		chmod(0600, $file);

		return $self->object_from_response($data, $url);
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
	if ('domain'		eq $data->{'objectClassName'}) 	{ return Net::RDAP::Object::Domain->new($data, $url)	}
	elsif ('ip network'	eq $data->{'objectClassName'})	{ return Net::RDAP::Object::IPNetwork->new($data, $url)	}
	elsif ('autnum'		eq $data->{'objectClassName'})	{ return Net::RDAP::Object::Autnum->new($data, $url)	}
	elsif ('nameserver'	eq $data->{'objectClassName'})	{ return Net::RDAP::Object::Nameserver->new($data, $url)}
	elsif ('entity'		eq $data->{'objectClassName'})	{ return Net::RDAP::Object::Entity->new($data, $url)	}

	#
	# search results
	#
	elsif (defined($data->{'domainSearchResults'}))		{ return Net::RDAP::SearchResult->new($data, $url) }
	elsif (defined($data->{'nameserverSearchResults'}))	{ return Net::RDAP::SearchResult->new($data, $url) }
	elsif (defined($data->{'entitySearchResults'}))		{ return Net::RDAP::SearchResult->new($data, $url) }

	#
	# unprocessable response
	#
	else {
		return $self->error(
			'url'		=> $url,
			'errorCode'	=> 500,
			'title'		=> "Unknown objectClassName '$data->{'objectClassName'}'",
			'description'	=> [ "Unknown objectClassName '$data->{'objectClassName'}'" ],
		);
	}
}

#
# simple check that a server response is indeed an RDAP object
#
sub is_rdap {
	my ($self, $response) = @_;

	return ('file' eq $response->base->scheme || $response->header('Content-Type') =~ /^application\/rdap\+json/);
}

#
# wrapper function
#
sub request {
	my ($self, $req) = @_;
	return $self->ua->request($req);
}

=pod

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
	$NET::RDAP::Registry::UA = $self->{'ua'} if (!defined($NET::RDAP::Registry::UA));
	return $self->{'ua'};
}

#
# generate an error
#
sub error {
	my ($self, %params) = @_;
	return Net::RDAP::Error->new(
		{
			'errorCode' => $params{'errorCode'},
			'title'	=> $params{'title'},
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

Copyright 2018 CentralNic Ltd. All rights reserved.

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
