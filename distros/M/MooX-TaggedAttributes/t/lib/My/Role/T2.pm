package My::Role::T2;

use Moo::Role;

use MooX::TaggedAttributes -tags => [qw( T2_1 T2_2 )], -propagate;

use namespace::clean -except => [ '_tag_list', '_tags' ];

has t2_1 => ( is => 'ro', default => 't2_1.v' );

1;
