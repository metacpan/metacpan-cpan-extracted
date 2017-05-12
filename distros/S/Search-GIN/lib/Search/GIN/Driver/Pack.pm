use strict;
use warnings;
package Search::GIN::Driver::Pack;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

with qw(
    Search::GIN::Driver::Pack::Values
    Search::GIN::Driver::Pack::IDs
);

1;
