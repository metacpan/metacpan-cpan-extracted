# ============================================================================
package Test03CommandBase;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose;

has 'private' => (
    is              => 'rw',
    isa             => 'Str',
);

__PACKAGE__->meta->make_immutable;
1;