use strict;
use LWP::UserAgent;
use HTTP::Request;

our $VERSION = '0.1';

#{{{ package Util
package Util;
#{{{ is200
sub is200 
{
	my $rc = shift;
	return $rc >= 200 && $rc < 300;
}
#}}}
#}}}

#{{{ package Constants
package Constants;
$Constants::authURL = 'https://api.mosso.com/auth';
#}}}

#{{{ package Authentication
package Authentication;
use Moose;

has username => (is => 'ro', required => 1);
has apiKey => (is => 'ro', required => 1);

sub authenticate
{
	my $self = shift;

	my $ua = LWP::UserAgent->new();

	my $response = $ua->get($Constants::authURL,
		'x-auth-user' => $self->username,
		'x-auth-key' => $self->apiKey,
		'User-Agent' => "perl-cloudfiles/0.1"
	);

	return (
		$response->header('x-storage-url'),
		$response->header('x-cdn-management-url'),
		$response->header('x-auth-token')
	);
}

#}}}

#{{{ package Connection
package Connection;
use Moose;

has 'username' => (is => 'ro', required => 1);
has 'apiKey' => (is => 'ro', required => 1);
has 'authToken';
has 'url';
has 'cdnURL';
has 'userAgent';
has 'auth';

#{{{ BUILD
sub BUILD
{
	my $self = shift;

	$self->{auth} = Authentication->new(
		username => $self->username, apiKey => $self->apiKey);

	($self->{url}, $self->{cdnURL}, $self->{authToken}) =
		$self->{auth}->authenticate();

	$self->{userAgent} = LWP::UserAgent->new();
	$self->{userAgent}->default_header('x-auth-token' => $self->{authToken});
}
#}}}
#{{{ _makeRequest
sub _makeRequest
{
	my $self = shift;
	my $verb = shift;
	my $uri = shift;
	my $body = shift;
	my $headers = shift;

	$body = defined($body) ? $body : '';

	my %headers = defined($headers) ?  %{$headers} : ();

	my $request = HTTP::Request->new($verb => $self->{url} . "/$uri");
	$request->content($body);

	#Headers
	$request->header('Content-Length' => length($body));

	my $key;
	my $value;
	while (($key, $value) = each(%headers))
	{
		$request->header($key => $value);
	}

	return $self->{userAgent}->request($request);
}
#}}}

#{{{ createContainer
sub createContainer
{
	my $self = shift;
	my $name = shift;

	#Check for bad container name
	return 0 if (!defined($name) or $name =~ qr{.*/.*} or $name eq '');

	return Container->new(name => $name, conn => $self, create => 1);
}
#}}}
#{{{ deleteContainer
sub deleteContainer
{
	my $self = shift;
	my $name = shift;

	my $response = $self->_makeRequest('DELETE',$name);

	return Util::is200($response->code);
}
#}}}
#{{{ listContainers
sub listContainers
{
	my $self = shift;
	my $response = $self->_makeRequest('GET','');
	if (Util::is200($response->code))
	{
		return split("\n", $response->content);
	}
	
	return 0;
}
#}}}
#{{{ getContainer
sub getContainer
{
	my $self = shift;
	my $name = shift;

	return Container->new(name => $name, conn => $self);
}
#}}}
#}}}

#{{{ package Container
package Container;
use Moose;

has 'conn' => (is => 'ro', required => 1);
has 'name' => (is => 'ro', required => 1);

#Create the container? Otherwise Get it
has 'create' => (is => 'ro', default => 0);
has 'objectCount' => (is => 'ro');
has 'sizeUsed' => (is => 'ro');
has 'objectsList' => (is => 'ro');

#{{{ BUILD
sub BUILD
{
	my $self = shift;
	if ($self->create){
		#Create a new Container
		my $response = $self->conn->_makeRequest('PUT',$self->name);

	}else{
		#Get an already existing container

		my $response = $self->conn->_makeRequest('HEAD',$self->name);
		if(Util::is200($response->code))
		{
			$self->{objectCount} =
				$response->header('X-Container-Object-Count');
			$self->{sizeUsed} = $response->header('X-Container-Bytes-Used');

			#Succeeded
		}
	}
}
#}}}
#{{{ createObject
sub createObject
{
	my $self = shift;
	my $objectName = shift;
	my $data = shift;
	my $contentType = shift;

	#Check for bad object name
	#return 0 if (!defined($objectName) || /.*\/.*/ || $objectName eq '');
	return 0 if (!defined($objectName) or $objectName =~ qr{.*/.*}
		or $objectName eq '');

	my $o = StorageObject->new(
		name => $objectName, conn => $self->conn, container => $self);

	if (defined $data){
		$o->contentType($contentType) if (defined $contentType);
		$o->write($data);
	}

	return $o;
}
#}}}
#{{{ deleteObject
sub deleteObject
{
	my $self = shift;
	my $objectName = shift;
	my $data = shift;

	my $response =
		$self->conn->_makeRequest('DELETE',$self->name . "/$objectName", $data);

	return Util::is200($response->code);
}
#}}}
#{{{ listObjects
sub listObjects
{
	my $self = shift;
	#TODO: allow them to specify a search string of matching objs to list
	my $string = shift;

	my $response = $self->conn->_makeRequest('GET',$self->name);
	if (Util::is200($response->code))
	{
		return split("\n", $response->content);
	}

	return 0;
}
#}}}
#{{{ getObject
sub getObject
{
	my $self = shift;
	my $objectName = shift;

	return StorageObject->new(
		conn => $self->conn, container => $self, name => $objectName);
}
#}}}
#}}}

#{{{ package StorageObject
package StorageObject;
use Moose;
use Digest::MD5 qw(md5_hex);
use Date::Parse;

has 'container' => (is => 'ro', required => 1);
has 'name' => (is => 'ro', required => 1);
has 'conn' => (is => 'ro', required => 1);

has 'data' => (is => 'rw', default => '');
#Boolean, create object, otherwise get object
has 'create' => (is => 'ro');

has 'size' => (is => 'ro');
has 'contentType' => (is => 'rw', default => 'application/octet-stream');
has 'lastModified' => (is => 'ro', default => time());

#{{{ BUILD
sub BUILD
{
	my $self = shift;

	#Get an existing object on the server
	my $response = 
		$self->conn->_makeRequest('HEAD',
			$self->container->name . "/" . $self->name);

	if (Util::is200($response->code))
	{
		$self->{size} = $response->header('content-length');
		$self->{lastModified} =	
			str2time($response->header('last-modified'));
		$self->contentType($response->header('content-type'));
	}
}
#}}}
#{{{ read
sub read
{
	my $self = shift;

	my $parentName = $self->container->name;
	my $response = 
		$self->conn->_makeRequest('GET',"$parentName/" . $self->name);

	if (Util::is200($response->code)){
		$self->{size} = $response->header('content-length');
		$self->{lastModified} =	
			str2time($response->header('last-modified'));
		$self->contentType($response->header('content-type'));
		return $response->content();
	}
	return 0;
}
#}}}
#{{{ write
sub write
{
	my $self = shift;
	my $data = shift;

	$self->{data} = $data;
	$self->{size} = length($data);

	my %headers;
	%headers = (
		'content-type' => $self->contentType,
		'Etag' => md5_hex($self->data));

	my $response =
		$self->conn->_makeRequest(
			'PUT', $self->container->name . "/" . $self->name, 
			$self->data, \%headers);

	return Util::is200($response->code);
}
#}}}

#}}}

1;

# vim:ts=4:sw=4:fdm=marker
