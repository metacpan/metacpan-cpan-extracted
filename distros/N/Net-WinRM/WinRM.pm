package Net::WinRM;
our $VERSION = '1.00';


# Tied hash, represents a single WinRM request. In order to be sent,
# needs to be converted into XML, and using in http POST request
package Net::WinRM::Request;

use strict;
use warnings;
use Data::UUID;
use XML::Simple;
use HTTP::Request;
use Encode;

# new dummy. all common request fields are initialzed here
sub new
{
	my $self = bless {
		'xmlns:s'     => 'http://www.w3.org/2003/05/soap-envelope',
		'xmlns:wsa'   => 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
		'xmlns:wsman' => 'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd',
		's:Header'    => { 'wsa:ReplyTo' => { 'wsa:Address' => {
			content => 'http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous'
		}}},
		's:Body'      => {},
        }, shift;

	$self-> uuid;

	my %p = @_;
	while ( my ($k, $v) = each %p) {
		$self-> $k(( ref($v) and ref($v) eq 'ARRAY') ? @$v : $v);
	}

	return $self;
}

# external convertors
sub to_xml
{
	'<?xml version="1.0" encoding="UTF-8"?>' . 
	"\n" . 
	XMLout( { 's:Envelope' => $_[0] }, KeepRoot => 1, KeyAttr => [])
}

sub xml { new(@_)-> to_xml }

sub to_http_request
{
	my $self = shift;

	my $content = $self-> to_xml;

	Encode::_utf8_off($content);

	my $req = HTTP::Request-> new( POST => $self->{'s:Header'}->{'wsa:To'}->{'content'});
	$req-> header('Content-Type'   => 'application/soap+xml;charset=UTF-8');
	$req-> header('Content-Length' => length $content);
	$req-> content( $content);

	return $req;
}

sub uuid
{
	my ( $self) = shift;

	my $u  = Data::UUID-> new;
	my $ux = $u-> create;
	$ux = $u-> to_string( $ux);

	$self-> {'s:Header'}-> {'wsa:MessageID'} = {
		's:mustUnderstand' => 'true',
		'content' => "uuid:$ux"
	};
}

# lower-level modificators
sub action
{
	my ( $self, $action) = @_;

	$self-> {'s:Header'}-> {'wsa:Action'} = {
		's:mustUnderstand' => 'true',
		'content'          => "http://schemas.xmlsoap.org/ws/2004/09/$action"
	};
}

sub to
{
	my ( $self, $to) = @_;
	$self-> {'s:Header'}-> {'wsa:To'} = {
		's:mustUnderstand' => 'true',
		'content'          => "http://$to/wsman",
	};
}

sub class_namespace
{
	my ( $self, $class, $namespace) = @_;
	$namespace = 'root/cimv2' unless defined $namespace;
	$self-> {'s:Header'}-> {'wsman:ResourceURI'} = {
		's:mustUnderstand' => 'true',
		'content'          => "http://schemas.microsoft.com/wbem/wsman/1/wmi/$namespace/$class",
	};
}

# upper-level modificators
sub get
{
	my ( $self, $selector) = @_;
	$self-> action( 'transfer/Get');
	$self-> {'s:Header'}-> {'wsman:SelectorSet'} = {
		'wsman:Selector' => [ map {{
			Name     => $_,
			content  => $selector-> {$_},
		}} keys %$selector ],
	};
}

sub enumerate
{
	my ( $self, $keysonly, $wql, $max_elements ) = @_;

	$max_elements = 20 unless defined $max_elements;

	$self-> action('enumeration/Enumerate');
	$self->{'xmlns:wsen'} = 'http://schemas.xmlsoap.org/ws/2004/09/enumeration';
	$self->{'s:Body'}	  = {
		'wsen:Enumerate' => {
			'wsman:EnumerationMode'	    => {
				content => $keysonly ?
					'EnumerateEPR' :
					'EnumerateObjectAndEPR'
			},
			( $max_elements ? (
			'wsman:OptimizeEnumeration' => {},
			'wsman:MaxElements'         => { content => $max_elements },
			) : ())
		}
	};

	$self->{'s:Body'}->{'wsen:Enumerate'}->{'wsman:Filter'} = {
		Dialect => 'http://schemas.microsoft.com/wbem/wsman/1/WQL',
		content => $wql,
	} if defined $wql;
}

sub pull
{
	my ( $self, $ec) = @_;
	$self-> action( 'enumeration/Pull');
	$self-> {'xmlns:wsen'} = 'http://schemas.xmlsoap.org/ws/2004/09/enumeration';
	$self-> {'s:Body'} = {'wsen:Pull' => { 'wsen:EnumerationContext' => { content => $ec }}};
}

# Deciphers XML that is a response from a WinRM server, and stores the parsed
# data as a hash. Since WinRM may not return XML on occasions like
# authentication error, the class also accepts empty text to be initialized from
package Net::WinRM::Response;

use XML::Simple;

sub new
{
	if ( $_[1] =~ /^</) {
		# XMLin is stupid and treats anything not xmlish as a filename
		my $s = {};
		eval { $s = XMLin( $_[1], KeepRoot => 1); };

		return bless $s->{'s:Envelope'}, $_[0] if 
			UNIVERSAL::isa($s,'HASH') and 
			exists $s->{'s:Envelope'};
	}

	# empty object
	return bless {}, $_[0];
}

# traverses a path in the hash
sub fetch
{
	my ( $self, $path, $subtree) = @_;

	$subtree = $self unless defined $subtree;

	my @p = split('/', $path);

	while ( $subtree and UNIVERSAL::isa($subtree,'HASH')) {
		$path = shift @p;
		return unless exists $subtree-> {$path};
		return $subtree-> {$path} unless @p;
		$subtree = $subtree-> {$path};
	}

	return;
}

# returns WinRM error, if found
sub error
{
	my ( $self) = @_;

	my $r;
	
	$r = $self-> fetch('s:Body/s:Fault');
	return unless defined $r;

	return $r-> {'XMLFault'} if defined $r->{'XMLFault'};

	my $err = $self-> fetch(
		's:Detail/f:WSManFault/f:Message/f:ProviderFault/f:WSManFault/f:Message',
		$r
	);
	return $err if defined $err;

	return $self-> fetch( 's:Reason/s:Text/content', $r );
}

sub empty { 0 == scalar keys %{$_[0]} }

sub deserialize_property
{
	my ( $self, $v) = @_;
	if ( 
		ref($v) and 
		ref($v) eq 'HASH'
	) {
		if (
			1 == keys(%$v) and 
			$v->{'xsi:nil'}
		) {
			$v = undef;
		} elsif ( $v-> {'cim:Datetime'}) {
			$v = $v-> {'cim:Datetime'};
		} elsif ( $v-> {'a:ReferenceParameters'}) {
			$v = $self-> fetch(
				'a:ReferenceParameters/w:SelectorSet/w:Selector/content',
				$v
			);
		}
	}
	return $v;
}

# parses get/enumerate record and returns the deciphered hash
sub parse_record
{
	my ( $self, $h) = @_;

	my %resp;
	while ( my ( $k, $v) = each %$h) {
		next unless $k =~ s/^p://;
		$resp{$k} = $self-> deserialize_property($v);
	}
	return \%resp;
}

# parse XmlFragment returned by WQL queries
sub parse_fragment
{
	my ( $self, $h) = @_;

	my %resp;
	while ( my ( $k, $v) = each %$h) {
		next if $k =~ /^\w+:/;
		$resp{$k} = $self-> deserialize_property($v);
	}
	return \%resp;
}

# parses enumeration response, gets either sub-tree or an error
sub get_enumeration_body
{
	my $self = $_[0];
	return 
		$self-> fetch('s:Body/n:EnumerateResponse') ||
		$self-> fetch('s:Body/n:PullResponse')		||
		"bad response: no Body/<Pull|Enumerate> response";
}

# collection of winrm actions - get, enumerate.
package Net::WinRM;

use Carp;
use LWP::ConnCache;
use IO::Lambda qw(:all);
use IO::Lambda::HTTP qw(http_request);

sub new
{
	my ( $class, %opt) = @_;

	for ( qw(host class)) {
		croak "Net::WinRM::Protocol::new: option '$_' must be present"
			unless exists $opt{$_};
	}

	my $self = bless { 
		conn_cache => ($opt{conn_cache} || LWP::ConnCache-> new()),
		%opt 
	}, $class;

	return $self;
}

# given an action, creates a http request and options to http_request lambda
sub create_http_request
{
	my $self = shift;
	my $req  = Net::WinRM::Request-> new(
		to               => $self-> {host}, 
		class_namespace  => [ $self-> {class}, $self-> {namespace} ],
		@_
	)-> to_http_request;
	
	$req-> protocol('HTTP/1.1');
	$req-> header('Host'           => $self-> {host});
	$req-> header('Connection'     => 'Keep-Alive');
	$req-> header('Authorization'  => $self-> {authorization})
		if exists $self-> {authorization};
	
	my %ret = (
		max_redirect   => 0,
		conn_cache     => $self-> {conn_cache},
		timeout        => $self-> {timeout},
		deadline       => $self-> {deadline},
		ntlm_version   => $self-> {ntlm_version} || 1,
	);

	if ( defined $self-> {username}) {
		my $def_auth;
		if ( $self-> {username} =~ m{^(.*?)/(.*)$}) {
			$ret{domain}   = $1;
			$ret{username} = $2;
			$def_auth = 'Negotiate';
		} else {
			$ret{username} = $self-> {username};
			$def_auth = 'Basic';
		}
		$ret{password}       = $self-> {password};
		$ret{preferred_auth} = $self-> {preferred_auth} || $def_auth;
	}

	return $req, %ret;
}

# deals with http response from winrm server, but doesn't parse the winrm content
sub parse_http_response
{
	my ( $self, $r) = @_;
		
	return "communication error: $r" unless ref($r);

	my $res  = Net::WinRM::Response-> new( $r-> content);
	my $code = $r-> code;

	if ( $code !~ /^[25]/) {
		# authentications, redirects etc
		return defined($res-> error) ? 
			$res-> error : 
			"http error $code " . $r-> message
			;
	} elsif ( $code !~ /^2/) {
		# winrm 5XX errors 
		return defined($res-> error) ? 
			$res-> error : 
			'unknown winrm error'
			;
	}

	return $res;
}

# Creates a lambda that performs WinRM get request. Lambda returns either the instance hash,
# or error string
sub get
{
	my ($class, %opt) = @_;
	for ( qw(selector)) {
		croak "Net::WinRM::Protocol::get: option '$_' must be present"
			unless exists $opt{$_};
	}
	my $self = $class-> new( %opt);

	lambda {
		context $self-> create_http_request(
			get => $self-> {selector}
		);
	http_request {
		my $r = $self-> parse_http_response(shift);
		return $r unless ref($r);

		my $item = $r-> fetch("s:Body/p:" . $self->{class});
		return "bad response: no Body/Get response" unless $item;
		
		return $r-> parse_record( $item);
	}}
}

sub instances_add
{
	my ( $self, $r) = @_;
	
	my $t = $r-> get_enumeration_body;
	return $t unless ref($t);
	
	my $items =
		$r-> fetch('n:Items/a:EndpointReference', $t) ||
		$r-> fetch('w:Items/a:EndpointReference', $t);
	return unless $items;

	$items = [ $items ] if ref($items) eq 'HASH';
	for ( @$items) {
		my $param = $r-> fetch( 'a:ReferenceParameters', $_ );
		next unless $param;
 
		my $item = $r-> fetch( 'w:SelectorSet/w:Selector', $param ) || [];
		$item = [$item] unless ref($item) eq 'ARRAY';
 
		my $class = $r-> fetch( 'w:ResourceURI', $param );
		return 'pull: bad response - no ResourceURI'
			unless defined $class;
		return "pull: bad class($class)" unless $class =~ /\/(\w+)$/;
		$class = $1;
 
		my %keyset = ( _class => $class );
		for my $x (@$item) {
			next unless defined $x->{Name} and defined $x->{content};
			$keyset{ $x->{Name} } = $x->{content};
		}
 
		push @{ $self->{enumeration} }, \%keyset;
	}

	return undef;
}

sub enumerate_add
{
	my ( $self, $r) = @_;
	
	my $t = $r-> get_enumeration_body;
	return $t unless ref($t);
	
	my $items =
		$r-> fetch('n:Items/w:Item', $t) ||
		$r-> fetch('w:Items/w:Item', $t);
	return undef unless $items;

	$items = [ $items ] if ref($items) eq 'HASH';

	for my $item ( @$items) {
		my @class = grep { /^p:/ } keys %$item;
		return "pull: ambiguous class set: @class" if 1 < @class;

		if (@class) {
			$item = $r-> parse_record( $item->{ $class[0] } );
			$class[0] =~ s/^p://;
			$item->{_class} = $class[0];
		} else {
			$item = $item->{'w:XmlFragment'}
				or return "pull: XmlFragment not present";
			$item = $r-> parse_fragment($item);
		}

		push @{ $self->{enumeration} }, $item;
	}

	return undef;
}

# Creates a lambda that performs WinRM ENUMERATE request. Lambda returns either the array of instance hashes,
# or error string
sub enumerator
{
	my ( $class, $instances, @opt) = @_;
	my $self = $class-> new(@opt);

	lambda {
		$self->{enumeration} = [];
		my ( $req, @options ) = $self-> create_http_request(
			enumerate => [ $instances, $self->{wql}, $self->{max_elements} ]
		);

	context $req, @options;
	http_request {
		$self-> {authorization} = $req-> header('Authorization');

		my $r = $self-> parse_http_response(shift);
		return $r unless ref($r);
 
		# negotiate enumeration, get the first enum uuid token
		my $t = $r-> get_enumeration_body;
		return $t unless ref $t;
		my $ec	= $t-> {'n:EnumerationContext'};
		my $end = 
			$t-> {'w:EndOfSequence'} ||
			$t-> {'n:EndOfSequence'};
		return 'bad response - no EnumerationContext'
			if not($end) and not($ec);

		# have any instances to add?
		my $err = $instances ? 
			$self-> instances_add( $r) :
			$self-> enumerate_add( $r);
		return $err if defined $err;

		# is it all already?
		return $self-> {enumeration} if $end;

		context $self-> create_http_request( pull => $ec );
		again;
   }}
}

sub instances { shift-> enumerator( 1, @_ ) }
sub enumerate { shift-> enumerator( 0, @_ ) }

1;

__DATA__

=pod

=head1 NAME

Net::WinRM - access WMI classes using WinRM

=head1 DESCRIPTION

This module provides access to WMI classes on remote windows machines.
A windows machine need to have WinRM installed and configured, and
you need valid login credentials.

=head1 SEE ALSO

F<bin/winrm> - example script for the interactive use

=cut
