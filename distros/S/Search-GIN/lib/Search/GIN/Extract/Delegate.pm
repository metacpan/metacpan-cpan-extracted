use strict;
use warnings;
package Search::GIN::Extract::Delegate;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

has extract => (
    does => "Search::GIN::Extract",
    is   => "ro",
    required => 1,
    # handles => "Search::GIN::Extract"
);

sub extract_values { shift->extract->extract_values(@_) }

1;
