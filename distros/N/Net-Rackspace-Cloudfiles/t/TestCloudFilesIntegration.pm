use strict;
package TestRackspaceCloudFilesIntegration;
use base qw(Test::Unit::TestCase);
use Net::Rackspace::CloudFiles;
use Data::Dumper;

my $username = 'USERNAME';
my $key = 'API_KEY';

#{{{ sub testIntegration
sub testIntegration
{
	my $self = shift;

	$self->{conn} = Connection->new(username => $username, apiKey => $key);
	
	# Create a container.
	my $containerName = 'asdf' . rand();
	my $container = $self->{conn}->createContainer($containerName);

	# Make sure the container is empty.
	my $numObjects = $container->listObjects();
	$self->assert_equals(0, $numObjects);

	# Create an object and add it to the container.
	my $objectName = 'testobject.txt';
	my $contents = 'blahblahblah';
	my $object = $container->createObject($objectName, $contents);

	# Check that the container now contains 1 item.
	my @objects = $container->listObjects();
	$numObjects = @objects;
	$self->assert_equals(1, $numObjects);

	# Check that the object we added is in the container.
	my $found = grep(/^$objectName$/, @objects);
	$self->assert($found);

	# Check that the contents of the object are correct.
	$object = $container->getObject($objectName);
	$self->assert_equals($objectName, $object->name);
	$self->assert_equals(length($contents), $object->size);
	$self->assert_equals($contents, $object->read());

	# Delete the object from the container.
	$container->deleteObject($objectName);

	# Check that there are no items left in the container.
	$numObjects = $container->listObjects();
	$self->assert_equals(0, $numObjects);

	# Delete the container.
	$self->{conn}->deleteContainer($containerName);

	# Check that our container was deleted.
	my @containers = $self->{conn}->listContainers();
	$found = grep(/^$containerName$/, @containers);
	$self->assert(!$found);
}
#}}}

1;
