package CombiningClass;

use Moose;
use namespace::autoclean;

with 'Role', 'UnrelatedRole';

1;
