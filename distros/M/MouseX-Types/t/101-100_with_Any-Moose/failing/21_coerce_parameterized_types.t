#!/usr/bin/env perl
use strict;
use warnings;
use Test::Exception;

use Test::More tests => 2;

BEGIN {
    package TypeLib;
    use MouseX::Types -declare => [qw/
	MyChar MyDigit ArrayRefOfMyCharOrDigit
    /];
    use MouseX::Types::Mouse qw/ArrayRef Str Int/;

    subtype MyChar, as Str, where {
	length == 1
    };

    subtype MyDigit, as Int, where {
	length == 1
    };

    coerce ArrayRef[MyChar|MyDigit], from Str, via {
	[split //]
    };

# same thing with an explicit subtype
    subtype ArrayRefOfMyCharOrDigit, as ArrayRef[MyChar|MyDigit];

    coerce ArrayRefOfMyCharOrDigit, from Str, via {
	[split //]
    };
}
{
    package AClass;
    use Mouse;
    BEGIN { TypeLib->import(qw/
	MyChar MyDigit ArrayRefOfMyCharOrDigit/
    ) };
    use MouseX::Types::Mouse 'ArrayRef';

    has parameterized => (is => 'rw', isa => ArrayRef[MyChar|MyDigit], coerce => 1);
    has subtype_parameterized => (is => 'rw', isa => ArrayRefOfMyCharOrDigit, coerce => 1);
}

my $instance = AClass->new;

{ local $TODO = "see comments in MouseX::Types->create_arged_...";
lives_ok { $instance->parameterized('foo') }
    'coercion applied to parameterized type';
}

lives_ok { $instance->subtype_parameterized('foo') }
    'coercion applied to subtype';
