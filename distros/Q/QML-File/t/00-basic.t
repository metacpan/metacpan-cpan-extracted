# Before `make install' is performed this script should be runnable with
# `make test'.

#########################

use Test::More tests => 11;
BEGIN { use_ok('QML::File') };

# Test that the appropriate methods exist
can_ok('QML::File',
    qw(new name imports objectType id propertyDeclarations signalDeclarations),
    qw(javaScriptFunctions objectProperties childObjects));

my $parser = QML::File->new('t/TestComponent.qml');

my @imports = $parser->imports;
is(scalar(@imports), 2, 'num imports');

my $componentName = $parser->name;
is($componentName, 'TestComponent', 'component name');

my $objectType = $parser->objectType;
is($objectType->{name}, 'Rectangle', 'object type');

my $id = $parser->id;
is($id->{name}, 'testComponent', 'component id');

my @properties = $parser->propertyDeclarations;
is(scalar(@properties), 1, 'property declarations');

my @signals = $parser->signalDeclarations;
is(scalar(@signals), 1, 'signal declarations');

my @functions = $parser->javaScriptFunctions;
is(scalar(@functions), 2, 'javascript functions');

my @objectProperties = $parser->objectProperties;
is(scalar(@objectProperties), 8, 'object properties');

my @childObjects = $parser->childObjects;
is(scalar(@childObjects), 1, 'child objects');

