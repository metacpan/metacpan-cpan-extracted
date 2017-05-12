package TAEB::Action::Zap;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';
with 'TAEB::Action::Role::Item' => { items => [qw/wand/] };

use constant command => 'z';

has '+wand' => (
    isa      => 'NetHack::Item::Wand',
    required => 1,
);

sub respond_zap_what    { shift->wand->slot }
sub msg_nothing_happens { shift->wand->charges(0) }
sub msg_wrest_wand      { TAEB->inventory->remove(shift->wand->slot) }
sub done                { shift->wand->spend_charge }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

