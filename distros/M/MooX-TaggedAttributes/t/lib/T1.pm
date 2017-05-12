package T1;

use Moo::Role;
use MooX::TaggedAttributes -tags => [ qw( T1_1 T1_2 ) ];

has t1_1 => ( is => 'ro', default => 't1_1.v' );

1;


