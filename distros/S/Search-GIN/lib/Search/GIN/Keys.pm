use strict;
use warnings;
package Search::GIN::Keys;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

requires qw(process_keys);

1;
