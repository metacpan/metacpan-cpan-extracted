
use strict;
use warnings;

package Object::HasExtraFieldsRA;

use Carp ();

use Mixin::ExtraFields
  -fields => {
    driver => { class => 'HashGuts', hash_key => '_extra' },
    id     => undef,
  },
;

sub new {
  return bless {} => shift;
}

1;
