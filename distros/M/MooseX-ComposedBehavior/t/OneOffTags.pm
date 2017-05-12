package t::OneOffTags;
use Moose::Role;

has tags => (
  isa => 'ArrayRef[Str]',
  traits   => [ 'Array' ],
  handles  => { _instance_tags => 'elements' },
  default  => sub {  []  },
  init_arg => 'tags',
);

1;
