package App::Foo::types;

use strict;
use warnings;

use constant CLASS => 'App::Foo';

use Type::Library -base;
use Type::Utils -all;
use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/Object Int/;

declare AppFooInterface => (
#   as Object,
    as Int,
#   where { ObjectDoesInterface[CLASS . '::interface']->check($_) },
    where { $_ % 2 },
);

1;
