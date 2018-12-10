package T2;

use Moo::Role;

use namespace::clean;

use MooX::TaggedAttributes -tags => [qw( T2_1 T2_2 )];

has t2_1 => ( is => 'ro', default => 't2_1.v' );

1;
