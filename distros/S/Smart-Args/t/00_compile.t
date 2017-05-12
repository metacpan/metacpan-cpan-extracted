use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Smart::Args' }

diag eval "require Mouse; 1;" ? "Mouse: $Mouse::VERSION" : 'no mouse';
diag eval "require Moose; 1;" ? "Moose: $Moose::VERSION" : 'no mouse';
diag eval "require MouseX::Types; 1;" ? "MouseX::Types: $MouseX::Types::VERSION" : 'no MouseX::Types';
diag eval "require MooseX::Types; 1;" ? "MooseX::Types: $MooseX::Types::VERSION" : 'no MooseX::Types';

