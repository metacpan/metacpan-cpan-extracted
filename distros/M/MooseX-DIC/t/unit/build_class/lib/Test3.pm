package Test3;

use Moose;

has dependency1 => ( is => 'ro', does => 'Test1', required => 1);
has dependency2 => ( is => 'ro', does => 'Test2');

1;
