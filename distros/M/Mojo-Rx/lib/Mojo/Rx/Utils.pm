package Mojo::Rx::Utils;
use strict;
use warnings FATAL => 'all';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/ get_subscription_from_subscriber /;

our $VERSION = "v0.12.1";

sub get_subscription_from_subscriber { $_[0]->{_subscription} }

1;
