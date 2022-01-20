package Foo;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::JSON qw( JSON relaxedJSON );

has config  => ( is => 'rw', isa => JSON        );
has options => ( is => 'rw', isa => relaxedJSON );
