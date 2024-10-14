package PDK::Device::Cisco::Ios;

use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
extends 'PDK::Device::Cisco';
use namespace::autoclean;


__PACKAGE__->meta->make_immutable;

1;
