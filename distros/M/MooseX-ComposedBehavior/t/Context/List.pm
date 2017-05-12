package t::Context::List;
use strict;

use MooseX::ComposedBehavior -compose => {
  method_name  => 'gather_lists',
  sugar_name   => 'add_list',
  also_compose => 'instance_list',
  context      => 'list',
  compositor   => sub { return wantarray ? (results => $_[1]) : $_[1] },
};

1;
