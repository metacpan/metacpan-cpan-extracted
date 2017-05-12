use strict;
use warnings;
package MooyClean;

use Moo;
use File::Spec::Functions 'catdir';
use namespace::clean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(catdir catfile devnull with) ];

1;
