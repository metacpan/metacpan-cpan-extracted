package MyTest;

use Moose;
use MooseX::Types::NumUnit qw/NumSI/;

has 'length' => ( isa => NumSI, is => 'rw', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;


package main;

use Test::More;

my $thingy = MyTest->new( length => '100 ft' );

is ($thingy->length, 30.48, 'Simple number converts on coersion');

done_testing;

