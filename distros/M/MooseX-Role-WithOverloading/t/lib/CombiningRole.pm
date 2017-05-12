package CombiningRole;

use Moose::Role;
use namespace::autoclean;

with 'Role', 'UnrelatedRole';

1;
