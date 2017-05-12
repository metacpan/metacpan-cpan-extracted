package NullFkWrapper;

#
#   TypeAdapter for columns/fields/method-Params/method-Results
#   which shall contain undef (null) too.
#
#   This is necessary especially when you want to "enter" a null,
#   e.g. in a Column- or ActionFixture.
#

use strict;
use base 'Test::C2FIT::TypeAdapter';

sub parse {
    my $self = shift;
    my ($s) = @_;

    return undef unless defined($s);
    return undef if $s eq "NULL";
    return $s;
}

1;
