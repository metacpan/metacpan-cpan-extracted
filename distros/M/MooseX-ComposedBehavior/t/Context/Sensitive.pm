package t::Context::Sensitive;
use strict;

use MooseX::ComposedBehavior -compose => {
  method_name  => 'gather_either',
  sugar_name   => 'add_either',
  also_compose => 'instance_either',
  compositor   => sub { return wantarray ? (results => $_[1]) : $_[1] },
};

1;
