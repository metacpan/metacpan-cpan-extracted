package Params::Registry::Error;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'Throwable::Error';

=head1 NAME

Params::Registry::Error - Structured exceptions for Params::Registry

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

package Params::Registry::Error::Syntax;

use Moose;
use namespace::autoclean;

extends 'Params::Registry::Error';

has value => (
    is  => 'ro',
    isa => 'Any',
);

package Params::Registry::Error::Processing;

use Moose;
use namespace::autoclean;

extends 'Params::Registry::Error';

has _p => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['Hash'],
    init_arg => 'parameters',
    handles  => {
        get        => 'get',
        parameters => 'keys',
        params     => 'keys',
    },
);

has message => (
    is      => 'ro',
    isa     => 'Str',
    default => 'One or more parameters has failed to process',
);

__PACKAGE__->meta->make_immutable;

1;
