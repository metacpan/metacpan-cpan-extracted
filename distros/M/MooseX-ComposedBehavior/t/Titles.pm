package t::Titles;
use strict;

use MooseX::ComposedBehavior -compose => {
  sugar_name   => 'add_title',
  also_compose => [ qw(job_title education) ],
  compositor   => sub {
    my ($self, $results) = @_;
    return map { @$_ } @$results if wantarray;
    return join q{, }, @$results;
  },
  method_name  => 'title',
};

1;
