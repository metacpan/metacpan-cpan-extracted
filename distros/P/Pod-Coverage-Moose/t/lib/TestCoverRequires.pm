package TestCoverRequires;

use Moose::Role;
use namespace::autoclean;

sub foo { }

requires 'bar';

1;
