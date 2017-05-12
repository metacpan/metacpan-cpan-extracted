use strict;
use warnings;
package MooseyClean;

use Moose;
use File::Spec::Functions 'catdir';
use namespace::clean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(catdir with) ];

1;
