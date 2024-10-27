package PDK::Device::Cisco::Ios;

use utf8;
use v5.30;
use Moose;
use Expect qw'exp_continue';
use Carp   qw'croak';
use namespace::autoclean;

extends 'PDK::Device::Cisco';


__PACKAGE__->meta->make_immutable;

1;
