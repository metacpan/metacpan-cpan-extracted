package Perl6::Junction::Base;
use strict;
our $VERSION = '1.60000';

use overload(
    '=='   => "num_eq",
    '!='   => "num_ne",
    '>='   => "num_ge",
    '>'    => "num_gt",
    '<='   => "num_le",
    '<'    => "num_lt",
    'eq'   => "str_eq",
    'ne'   => "str_ne",
    'ge'   => "str_ge",
    'gt'   => "str_gt",
    'le'   => "str_le",
    'lt'   => "str_lt",
    'bool' => "bool",
    '""'   => sub {shift},
);

sub new {
    my ( $class, @param ) = @_;
    return bless \@param, $class;
}

sub values {
    my $self = shift;
    return wantarray ? @$self : [ @$self ];
}

1;

