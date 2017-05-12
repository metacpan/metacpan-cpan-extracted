package TAEB::Action::Role::Monster;
use Moose::Role;

requires 'target_tile';

sub monster     { shift->target_tile->monster }
sub has_monster { shift->target_tile->has_monster }

no Moose::Role;

1;

