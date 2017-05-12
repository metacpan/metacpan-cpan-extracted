package IntrospectTypeExports;
use strict;
use warnings;

use Any::Moose 'X::Types::Util' => [qw( has_available_type_export )];

my @Memory;

sub import {
    my ($class, $package, @types) = @_;

    for my $type (@types) {
        my $tc     = has_available_type_export($package, $type);
        push @Memory, [$package, $type, $tc ? $tc->name : undef];
    }
}

sub get_memory { \@Memory }

1;
