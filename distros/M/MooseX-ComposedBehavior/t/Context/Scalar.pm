package t::Context::Scalar;
use strict;

use MooseX::ComposedBehavior -compose => {
  method_name  => 'gather_scalars',
  sugar_name   => 'add_scalar',
  also_compose => 'instance_scalar',
  context      => 'scalar',
  compositor   => sub { return wantarray ? (results => $_[1]) : $_[1] },
};

1;
