package Shell::EnvImporter::Change;

use strict;
use warnings;
no warnings 'uninitialized';

use Class::MethodMaker 2.0 [
    new     => [qw(-hash new)],
    scalar  => [qw(
      type
      value
    )],
  ];

use constant TYPES => (
  qw(modified added removed)
);


1;
