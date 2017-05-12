use strict;
use warnings;
package Search::GIN::Driver::Pack::Values;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

requires qw(pack_values unpack_values);

1;
