package TestRole;

use strict;
use warnings;

use Simple::Accessor qw{name};

with 'Role::Age';
with 'Role::Time';

sub _build_name { 'default-name' }

1;