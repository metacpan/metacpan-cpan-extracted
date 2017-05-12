package MXDefaultMultipleConfigsTest;
use Moose;

extends 'MXDefaultConfigTest';

has '+configfile' => ( default => sub { [ 'test.yaml' ] } );

no Moose;
1;
