use strict;
use warnings;
use Class::MOP::Class;

my $meta = Class::MOP::Class->create('ClassMOPClean');

package ClassMOPClean;
use File::Spec::Functions 'catdir';
use namespace::clean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(catdir catfile devnull) ];

1;
