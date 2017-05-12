package MyTest;

use Moose;
use MooseX::Types::NumUnit qw/NumUnit/;

has 'length' => ( isa => NumUnit, is => 'rw', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;


package main;

use Test::More;

my $thingy = MyTest->new( length => '100 ft' );

is ($thingy->length, 100, 'NumUnit type strips unit and returns value');

done_testing;

