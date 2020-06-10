package Mojo::Rx::Utils;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT_OK = qw/ get_subscription_from_subscriber /;

our $VERSION = "v0.13.0";

sub get_subscription_from_subscriber { $_[0]->{_subscription} }

1;
