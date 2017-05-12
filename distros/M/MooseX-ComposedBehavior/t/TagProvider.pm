package t::TagProvider;
use strict;

use MooseX::ComposedBehavior -compose => {
  role_name    => __PACKAGE__,
  sugar_name   => 'add_tags',
  also_compose => '_instance_tags',
  context      => 'list',
  compositor   => sub {
    my ($self, $results) = @_;
    return map { @$_ } @$results if wantarray;
  },
  method_name  => 'tags',
};

1;
