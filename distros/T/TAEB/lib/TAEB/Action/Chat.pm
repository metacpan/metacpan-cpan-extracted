package TAEB::Action::Chat;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';

use constant command => "#chat\n";

has '+direction' => (
    required => 1,
);

has amount => (
    is       => 'ro',
    isa      => 'Int',
    default  => 1,
    provided => 1,
);

sub respond_donate { shift->amount . "\n" }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

