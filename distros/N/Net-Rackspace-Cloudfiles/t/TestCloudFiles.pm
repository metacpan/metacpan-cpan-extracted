package TestCloudFiles;
use base qw(Test::Unit::TestCase);

use strict;
use Test::Mock::LWP;
#use Test::MockObject;
use Net::Rackspace::CloudFiles;
use Date::Parse;
use Data::Dumper;


#{{{ sub new
sub new
{
	my $self = shift()->SUPER::new(@_);
	$self->{headers} = \%Test::Mock::HTTP::Response::Headers;

	#Set up mock authorization stuff, so connection will work
	$self->setup_auth();
	$self->{conn} = Connection->new(username => 'test', apiKey => 'test');
	
	return $self;
}
#}}}
#{{{ sub set_up
sub set_up
{
	# provide fixture
	my $self = shift;
}
#}}}
#{{{ sub tear_down
sub tear_down
{
	# clean up after test
	my $self = shift;
}
#}}}

# Helper Functions
#{{{ setup_container
sub setup_container
{
	my $self = shift;

	# Create a container
	my $containerName = 'testcontainer';
	$self->{container} = Container->new(
		conn => $self->{conn}, name => $containerName);
}
#}}}
#{{{ setup_object
sub setup_object
{
	my $self = shift;

	# Create a container
	my $objectName = 'testObject';
	$self->{container} = Container->new(
		conn => $self->{conn}, name => $objectName);

	return $objectName;
}
#}}}
#{{{ setup_auth
sub setup_auth
{
	my $self = shift;

    $Mock_resp->mock( content => sub { 'foo' } );
    $Mock_resp->mock( code => sub { 201 } );

	my @expected = ('asdf', 'aaa', 'token');

	$self->{headers}{'x-storage-url'} = $expected[0];
	$self->{headers}{'x-cdn-management-url'} = $expected[1];
	$self->{headers}{'x-auth-token'} = $expected[2];

	$Mock_ua->mock('get', sub { return $Mock_resp});
	$Mock_ua->mock('default_header', sub { return 1;});

	return @expected;
}
#}}}

# Util Tests
#{{{ sub testUtil
sub testUtil
{
	my $self = shift;

	$self->assert(Util::is200(200));
	$self->assert(Util::is200(299));
	$self->assert(!Util::is200(199));
	$self->assert(!Util::is200(300));
}
#}}}

# Authentication Tests
#{{{ sub testAuthenticate
sub testAuthenticate
{
	my $self = shift;

	my @expected = $self->setup_auth()	;
	my $auth = Authentication->new(username => 'asdf',apiKey => 'asdfsfad');
	my @values = $auth->authenticate();

	# Check that @expected == @values.
	map($self->assert_equals($_, shift(@values)), @expected);
}
#}}}

# StorageObject Tests

# Container Tests
#{{{ sub testCreateObjectWithoutData
sub testCreateObjectWithoutData
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_ua->mock('request' => sub { $Mock_resp });

	my $objectName = 'testObject.txt';
	my $object = $self->{container}->createObject($objectName);

	#Check that it is a StorageObject
	$self->assert(ref($object) eq 'StorageObject');
	#Check that its name is correct
	$self->assert($object->name eq $objectName);
}
#}}}
#{{{ sub testCreateObjectWithData
sub testCreateObjectWithData
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	my $objectName = 'testObject.txt';
	my $data = 'test data for test object';
	my $lastModified = 'Fri, 7 Feb 2009 09:50:32 -0500 (EST)';
	#default content-type
	my $contentType = 'application/octet-stream';

	# Set up headers
	$self->{headers}{'content-length'} = length($data);
	$self->{headers}{'last-modified'} = $lastModified;
	#make this empty to make sure the default gets set
	$self->{headers}{'content-type'} = '';

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_resp->mock( content => sub { $data } );
	$Mock_ua->mock('request' => sub { $Mock_resp});

	my $object = $self->{container}->createObject($objectName, $data);

	#Check that it is a StorageObject
	$self->assert(ref($object) eq 'StorageObject');
	#Check that its name is correct
	$self->assert($object->name eq $objectName);
	#Check that the data is correct
	$self->assert($object->read eq $data);
	#Check that the Content-Length is correct
	$self->assert($object->size eq length($data));
	#Check that the Last-Modfied header is correct
	$self->assert($object->lastModified eq str2time($lastModified));
}
#}}}
#{{{ sub testCreateObjectWithContentType
sub testCreateObjectWithContentType
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	my $objectName = 'testObject.txt';
	my $data = 'test data for test object';
	my $contentType = 'test/content-type';
	my $lastModified = 'Fri, 7 Feb 2009 09:50:32 -0500 (EST)';

	# Set up headers
	$self->{headers}{'content-length'} = length($data);
	$self->{headers}{'last-modified'} = $lastModified;
	$self->{headers}{'content-type'} = $contentType;

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_resp->mock( content => sub { $data } );

	my $object = $self->{container}->createObject(
		$objectName, $data, $contentType);

	#Check that it is a StorageObject
	$self->assert(ref($object) eq 'StorageObject');
	#Check that its name is correct
	$self->assert($object->name eq $objectName);
	#Check that the data is correct
	$self->assert($object->read eq $data);
	#Check that the Content-Length is correct
	$self->assert($object->size eq length($data));
	#Check that the Content-Type is correct
	$self->assert($object->contentType eq $contentType);
	#Check that the Last-Modfied header is correct
	$self->assert($object->lastModified eq str2time($lastModified));
}
#}}}
#{{{ sub testDeleteObjectFail
sub testDeleteObjectFail
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	$Mock_resp->mock( code => sub { 400 } );
	$Mock_ua->mock('request' => sub { $Mock_resp });

	my $objectName = 'testObject.txt';
	my $reval = $self->{container}->deleteObject($objectName);

	$self->assert(!$reval);
}
#}}}
#{{{ sub testDeleteObjectSuccess
sub testDeleteObjectSuccess
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_ua->mock('request' => sub { $Mock_resp });

	my $objectName = 'testObject.txt';
	my $reval = $self->{container}->deleteObject($objectName);

	$self->assert($reval);
}
#}}}
#{{{ sub testGetObject
sub testGetObject
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	my $objectName = 'testObject.txt';
	my $data = 'test data for test object';
	my $lastModified = 'Fri, 7 Feb 2009 09:50:32 -0500 (EST)';
	#default content-type
	my $contentType = 'application/octet-stream';

	# Set up headers
	$self->{headers}{'content-length'} = length($data);
	$self->{headers}{'last-modified'} = $lastModified;

	#make this empty to make sure the default gets set
	$self->{headers}{'content-type'} = '';

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_resp->mock( content => sub { $data } );
	$Mock_ua->mock('request' => sub { $Mock_resp});

	my $object = $self->{container}->getObject($objectName);

	#Check that it is a StorageObject
	$self->assert(ref($object) eq 'StorageObject');
	#Check that its name is correct
	$self->assert($object->name eq $objectName);
	#Check that the data is correct
	$self->assert($object->read eq $data);
	#Check that the Content-Length is correct
	$self->assert($object->size eq length($data));
	#Check that the Last-Modfied header is correct
	$self->assert($object->lastModified eq str2time($lastModified));
}
#}}}
#{{{ sub testListObjects
sub testListObjects
{
	my $self = shift;

	# Set up container object
	$self->setup_container();

	$Mock_resp->mock( code => sub { 204 } );
	$Mock_resp->mock( content => sub { "1.txt\n2.txt\n3.txt"} );
	$Mock_ua->mock('request' => sub { return $Mock_resp});

	my $objectName = 'objectTest';
	my @objects = $self->{container}->listObjects($objectName);

	$self->assert($objects[0] eq '1.txt');
	$self->assert($objects[1] eq '2.txt');
	$self->assert($objects[2] eq '3.txt');
}
#}}}
#{{{ sub testBadObjectNames
sub testBadObjectNames
{
	my $self = shift;
	
	# Set up container object
	$self->setup_container();

	my @badnames = ('','bad/filename','/badfilename','badfilename/');

	foreach (@badnames){
		$self->assert(!$self->{container}->createObject($_));
	}
}
#}}}

# Connection Tests
#{{{ sub testCreateContainer
sub testCreateContainer
{
	my $self = shift;

	$Mock_resp->mock( code => sub { 201 } );
	$Mock_ua->mock('request' => sub { $Mock_resp});

	my $containerName = 'containerTest';
	my $container = $self->{conn}->createContainer($containerName);

	# Check that it is a container object
	$self->assert(ref($container) eq 'Container');
	# Check that the name is correct
	$self->assert($container->name eq $containerName);
}
#}}}
#{{{ sub testDeleteContainerFail
sub testDeleteContainerFail
{
	my $self = shift;

	$Mock_resp->mock( code => sub { 400 } );
	$Mock_ua->mock('request' => sub { $Mock_resp});

	my $containerName = 'containerTest';
	my $reval = $self->{conn}->deleteContainer($containerName);

	$self->assert(!$reval);
}
#}}}
#{{{ sub testDeleteContainer
sub testDeleteContainer
{
	my $self = shift;

	$Mock_resp->mock( code => sub { 204 } );
	$Mock_ua->mock('request' => sub { $Mock_resp});

	my $containerName = 'containerTest';
	my $reval = $self->{conn}->deleteContainer($containerName);

	$self->assert($reval);
}
#}}}
#{{{ sub testGetContainer
sub testGetContainer
{
	my $self = shift;

	$Mock_resp->mock( code => sub { return 204 } );
	$Mock_ua->mock('request' => sub { return $Mock_resp});

	my $containerName = 'containerTest';
	my $container = $self->{conn}->getContainer($containerName);
	
	# Check that it is a container object
	$self->assert(ref($container) eq 'Container');
	# Check that the name is correct
	$self->assert($container->name eq $containerName);
}
#}}}
#{{{ sub testListContainers
sub testListContainers
{
	my $self = shift;

	$Mock_resp->mock( code => sub { 204 } );
	$Mock_resp->mock( content => sub { "1\n2\n3"} );
	$Mock_ua->mock('request' => sub { return $Mock_resp});

	my $containerName = 'containerTest';
	my @containers = $self->{conn}->listContainers($containerName);

	$self->assert($containers[0] eq '1');
	$self->assert($containers[1] eq '2');
	$self->assert($containers[2] eq '3');
}
#}}}
#{{{ sub testBadContainerNames
sub testBadContainerNames
{
	my $self = shift;

	my @badnames = ('','bad/filename','/badfilename','badfilename/');
	foreach (@badnames){
		$self->assert(!$self->{conn}->createContainer($_));
	}
}
#}}}

1;



# vim:ts=4:sw=4:fdm=marker
