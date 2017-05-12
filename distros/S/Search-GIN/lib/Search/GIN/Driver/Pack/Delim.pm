use strict;
use warnings;
package Search::GIN::Driver::Pack::Delim;

our $VERSION = '0.11';

use Moose::Role;
use namespace::autoclean;

sub pack_delim {
    my ( $self, @strings ) = @_;
    join("\0", @strings );
}

sub unpack_delim {
    my ( $self, $string ) = @_;
    split("\0", $string );
}

1;
