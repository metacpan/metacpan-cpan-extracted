package t::lib::Parameterized;
use MooseX::Role::Parameterized;

use namespace::autoclean;

parameter option => (
  isa      => 'Str',
  required => 1,
);

role {
  my $p = shift;

  method 'method_' . $p->option => sub {};
};

1;
