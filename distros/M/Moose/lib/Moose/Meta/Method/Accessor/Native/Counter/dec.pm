package Moose::Meta::Method::Accessor::Native::Counter::dec;
our $VERSION = '2.4000';

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer';

sub _minimum_arguments { 0 }
sub _maximum_arguments { 1 }

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return $slot_access . ' - (defined $_[0] ? $_[0] : 1)';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return $slot_access . ' -= defined $_[0] ? $_[0] : 1;';
}

no Moose::Role;

1;
