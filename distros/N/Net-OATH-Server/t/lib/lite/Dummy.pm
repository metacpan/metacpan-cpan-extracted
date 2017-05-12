package Dummy;
use strict;
use warnings;

use parent 'Class::Accessor::Fast';
use Params::Validate qw(SCALAR);

__PACKAGE__->mk_accessors(qw(
    dummy
));

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

1;
