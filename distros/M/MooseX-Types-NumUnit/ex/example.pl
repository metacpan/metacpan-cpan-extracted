package MyTest;

use lib 'lib';
use Moose;
use MooseX::Types::NumUnit qw/num_of_unit/;

$MooseX::Types::NumUnit::Verbose = 1;

has 'length' => ( isa => num_of_unit( 'm' ), is => 'rw', default => '1 ft' );
has 'speed' => ( isa => num_of_unit('ft / hour'), is => 'rw', required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

my $test = MyTest->new( speed => '2 m / s' );

print $test->speed, "\n";
print $test->length, "\n";

__END__

prints:
23622.0472440945
0.3048

