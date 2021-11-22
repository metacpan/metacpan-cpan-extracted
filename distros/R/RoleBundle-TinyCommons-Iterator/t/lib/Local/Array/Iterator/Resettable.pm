package # hide from PAUSE
    Local::Array::Iterator::Resettable;

use parent 'Local::Array::Iterator::Basic';
use Role::Tiny::With;

with 'Role::TinyCommons::Iterator::Resettable';

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

1;
