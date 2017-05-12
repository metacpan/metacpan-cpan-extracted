package t::Concatenator;
use strict;

use MooseX::ComposedBehavior -compose => {
  sugar_name   => 'add_result',
  also_compose => '_instance_result',
  compositor   => sub {
    my ($self, $results) = @_;
    return wantarray ? @$results : $results;
  },
  method_name  => 'results',
};

1;
