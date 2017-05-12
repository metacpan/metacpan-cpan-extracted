
use strict;
use warnings;

package Object::HasExtraFields;

use Carp ();

use Mixin::ExtraFields
  -fields => {
    driver => { class => 'HashGuts', hash_key => '_extra' },
    id => 'alt_id',
  },
  -fields => { driver => 'HashGuts',       moniker => 'misc' },
  -fields => { driver => '+MEFD::Minimal', moniker => 'mini' };

sub new {
  return bless {} => shift;
}

sub id {
  return unless ref $_[0];
  "id_" . (0 + $_[0]);
}

sub alt_id { 0 } # pretty lame for a unique id, huh?

1;
