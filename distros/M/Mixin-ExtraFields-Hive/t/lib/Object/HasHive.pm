
use strict;
use warnings;

package Object::HasHive;

use Carp ();

use Mixin::ExtraFields::Hive
  -hive => { driver => 'HashGuts' },
  -hive => {
    driver => { class => 'HashGuts', hash_key => '__nest' },
    moniker => 'nest',
  };

sub new {
  return bless {} => shift;
}

sub id {
  Carp::croak "not given an object" unless ref $_[0];
  0 + $_[0];
}

1;
