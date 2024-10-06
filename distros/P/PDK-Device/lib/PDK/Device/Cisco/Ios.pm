package PDK::Device::Cisco::Ios;

use 5.030;
use strict;
use warnings;

use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
extends 'PDK::Device::Cisco';
use namespace::autoclean;

__PACKAGE__->meta->make_immutable;
1;
