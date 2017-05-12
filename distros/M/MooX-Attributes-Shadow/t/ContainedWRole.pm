package ContainedWRole;

use Moo;

with 'MooX::Attributes::Shadow::Role';

has a => ( is => 'ro', default => sub { 'a' } );
has b => ( is => 'ro', default => sub { 'b' } );

shadowable_attrs( 'a', 'b' );


1;

