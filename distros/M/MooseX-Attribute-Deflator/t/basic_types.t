package Test;

use Moose;
use JSON;
use DateTime;
use Moose::Object;

use MooseX::Attribute::Deflator::Moose;
use MooseX::Attribute::Deflator;

deflate 'DateTime', via { $_->epoch }, inline_as {'$value->epoch'};
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) },
    inline_as {'DateTime->from_epoch( epoch => $value )'};

my $mo = Moose::Object->new;
deflate 'Moose::Object', via {1};
inflate 'Moose::Object', via {$mo};

my $dt = DateTime->now;

has hashref => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Deflator'],
    lazy    => 1,
    default => sub { { foo => 'bar' } }
);

has hashrefarray => (
    is      => 'rw',
    isa     => 'HashRef[ArrayRef[HashRef]]',
    traits  => ['Deflator'],
    default => sub { { foo => [ { foo => 'bar' } ] } },
);

has datetime => (
    is       => 'rw',
    isa      => 'DateTime',
    required => 1,
    default  => sub {$dt},
    traits   => ['Deflator']
);

has datetimearrayref => (
    is       => 'rw',
    isa      => 'ArrayRef[DateTime]',
    required => 1,
    default  => sub { [ $dt, $dt->clone->add( hours => 1 ) ] },
    traits   => ['Deflator']
);

has scalarint => (
    is       => 'rw',
    isa      => 'ScalarRef[Int]',
    required => 1,
    default  => sub { \1 },
    traits   => ['Deflator']
);

has bool =>
    ( is => 'rw', isa => 'Bool', default => 1, traits => ['Deflator'] );

has no_type => ( is => 'rw', traits => ['Deflator'], default => 'no_type' );

has not_inlined => (
    is      => 'ro',
    isa     => 'ArrayRef[Moose::Object]',
    default => sub { [$mo] },
    traits  => ['Deflator'],
);

package main;
use strict;
use warnings;
use Test::More;

my $results = {
    hashref          => '{"foo":"bar"}',
    hashrefarray     => '{"foo":"[\"{\\\\\"foo\\\\\":\\\\\"bar\\\\\"}\"]"}',
    no_type          => 'no_type',
    bool             => 1,
    scalarint        => 1,
    datetime         => $dt->epoch,
    not_inlined      => '[1]',
    datetimearrayref => '['
        . $dt->epoch . ','
        . $dt->clone->add( hours => 1 )->epoch . ']',
};

for ( 1 .. 2 ) {
    my $obj = Test->new;
    foreach my $attr ( Test->meta->get_all_attributes ) {
        ok( $attr,                   "work on attribute " . $attr->name );
        ok( !$attr->has_value($obj), 'attribute has no value' )
            if ( $attr->name eq 'hashref' );
        is( $attr->deflate($obj),
            $results->{ $attr->name },
            "result is $results->{$attr->name}"
        );

        ok( $attr->has_value($obj), 'deflate sets object value' )
            if ( $attr->name eq 'hashref' );

        is_deeply(
            $attr->inflate( $obj, $results->{ $attr->name } ),
            $attr->get_value($obj),
            "inflates $results->{$attr->name} correctly"
        );

        next if ( $attr->name eq 'not_inlined' );

        is( $attr->is_deflator_inlined,
            $Moose::VERSION >= 1.9 ? 1 : 0,
            'deflator inlined'
        );
        is( $attr->is_inflator_inlined,
            $Moose::VERSION >= 1.9 ? 1 : 0,
            'inflator inlined'
        );
    }

    {
        my $attr = Test->meta->get_attribute('hashref');
        is( $attr->deflate( $obj, { one => 'two' } ),
            '{"one":"two"}', 'deflate with optional value' );
    }

    diag "making immutable" if ( $_ eq 1 );
    Test->meta->make_immutable;
}

done_testing;
