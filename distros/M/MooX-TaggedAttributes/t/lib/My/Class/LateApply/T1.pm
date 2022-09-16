package My::Class::LateApply::T1;

use Moo::Role;
use MooX::TaggedAttributes -tags => [qw( tag1 tag2 )];

has t1_1 => ( is => 'ro', default => 't1_1.v' );

1;
