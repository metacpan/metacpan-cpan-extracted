package TestCollection;

use strict;
use warnings;

use Error;
use Pangloss::StoredObject::Error;
use base qw( Pangloss::Collection );

sub error_key_nonexistent {
    my $self = shift;
    my $key  = shift;
    local $Error::Depth = $Error::Depth + 2;
    throw Pangloss::StoredObject::Error(flag => eNonExistent, key => $key);
}

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    local $Error::Depth = $Error::Depth + 2;
    throw Pangloss::StoredObject::Error(flag => eExists, key => $key);
}

1;
