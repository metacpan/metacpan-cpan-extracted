#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyBenchmark;

use Moose;
use JSON;
use DateTime;

use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator;

has hashref => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Deflator'],
    default => sub { { foo => 'bar' } }
);

package main;
use strict;
use warnings;
use JSON;
use Benchmark qw(:all);

my $obj  = MyBenchmark->new;
my $attr = $obj->meta->get_attribute('hashref');

cmpthese(
    1_000_000,
    {   deflate => sub {
            $attr->deflate($obj);
        },
        get_value => sub {
            JSON::encode_json( $attr->get_value( $obj, 'hashref' ) );
        },
        accessor => sub {
            my $value = $_[0];
            $value = $obj->hashref unless ( defined $value );
            local $@;
            my $deflated = eval { JSON::encode_json($value) };
            if ($@) { die "foo" }
            return $deflated;
            }
    }
);

