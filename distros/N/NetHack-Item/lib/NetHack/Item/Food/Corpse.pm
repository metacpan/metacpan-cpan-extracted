package NetHack::Item::Food::Corpse;
{
  $NetHack::Item::Food::Corpse::VERSION = '0.21';
}
use Moose;
extends 'NetHack::Item::Food';

use constant subtype => 'corpse';

__PACKAGE__->meta->install_spoilers(qw/
    acidic aggravate cannibal cold_resistance cure_stone die
    disintegration_resistance energy fire_resistance gain_level hallucination
    heal intelligence invisibility less_confused less_stunned lycanthropy mimic
    monster permanent petrify poison_resistance poisonous polymorph reanimates
    see_invisible shock_resistance sleep_resistance slime speed_toggle strength
    stun telepathy teleport_control teleportitis
/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

