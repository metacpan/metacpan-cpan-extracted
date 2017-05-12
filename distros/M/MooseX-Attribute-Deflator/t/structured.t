use Test::More;
use strict;
use warnings;
package MyTest;

use Moose;
use DateTime;

use MooseX::Types::Moose qw(Str Int HashRef ArrayRef Maybe Undef);
use MooseX::Types::Structured qw(Dict Tuple Map Optional);
use MooseX::Types -declare =>
    [qw(Fullname Person StringIntMaybeHashRef MyDT)];

use MooseX::Attribute::Deflator::Structured;
use MooseX::Attribute::Deflator::Moose;

use MooseX::Attribute::Deflator;
deflate 'DateTime', via { $_->epoch }, inline_as {'$value->epoch'};
inflate 'DateTime', via { DateTime->from_epoch( epoch => $_ ) },
    inline_as {'DateTime->from_epoch( epoch => $value )'};
no MooseX::Attribute::Deflator;

class_type 'DateTime';
subtype MyDT, as 'DateTime';

subtype Fullname, as Dict [
    first  => Str,
    last   => Str,
    middle => Optional [ ArrayRef [Str] ]
];

subtype Person, as Dict [
    name     => Fullname,
    birthday => Optional [MyDT],

    #friends=>Optional[
    #        ArrayRef[Person]
    #],
];

subtype StringIntMaybeHashRef, as Tuple [ Str, Int, MyDT, Maybe [HashRef] ];

has fullname => ( is => 'rw', isa => Fullname, traits => ['Deflator'] );

has person => ( isa => Person, is => 'rw', traits => ['Deflator'] );

has person2 => ( isa => Person, is => 'rw', traits => ['Deflator'] );

has tuple =>
    ( isa => StringIntMaybeHashRef, is => 'rw', traits => ['Deflator'] );

has map => ( isa => Map [ Str, MyDT ], is => 'rw', traits => ['Deflator'] );

package main;

use JSON;
use DateTime;

my $now = DateTime->now;

my @test = (
    {   attribute => 'fullname',
        value     => { first => 'Moritz', last => 'Onken' },
        deflated  => { first => 'Moritz', last => 'Onken' }
    },
    {   attribute => 'tuple',
        value =>
            [ 'Hello', 100, $now, { key1 => 'value1', key2 => 'value2' } ],
        deflated => [
            'Hello', 100, $now->epoch, '{"key1":"value1","key2":"value2"}'
        ]
    },
    {   attribute => 'person',
        value     => { name => { first => 'Moritz', last => 'Onken' } },
        deflated => { name => '{"first":"Moritz","last":"Onken"}' }
    },
    {   attribute => 'person2',
        value     => {
            birthday => $now,
            name =>
                { first => 'Moritz', middle => ['Theodor'], last => 'Onken' }
        },
        deflated => {
            birthday => $now->epoch,
            name =>
                '{"first":"Moritz","last":"Onken","middle":"[\"Theodor\"]"}'
        }
    },
    {   attribute => 'map',
        value => { Peter => $now, Moritz => $now->clone->add( days => 2 ) },
        deflated => {
            Peter  => $now->epoch,
            Moritz => $now->clone->add( days => 2 )->epoch
        }
    },

# {
# attribute => 'person',
# value => { name => { first => 'Moritz', last => 'Onken' }, friends => [{name => {first => 'Peter', last => 'Noob'}}] },
# deflated => { name => '{"first":"Moritz","last":"Onken"}'}
# }

);

my $obj = MyTest->new( map { $_->{attribute} => $_->{value} } @test );

foreach my $test (@test) {
    my $attribute = $obj->meta->get_attribute( $test->{attribute} );
    is( $attribute->is_deflator_inlined, $Moose::VERSION >= 1.9 ? 1 : 0, 'inlined deflator' );
    is( $attribute->is_inflator_inlined,
        $Moose::VERSION >= 1.9 ? 1 : 0,
        'inlined inflator'
    );
    is_deeply( $attribute->get_value($obj),
        $test->{value},
        'value of ' . $attribute->name . ' is set correctly' );
    my $json = $attribute->deflate($obj);
    is_deeply(
        decode_json($json),
        $test->{deflated} || $test->{value},
        'deflation of ' . $attribute->name . ' works'
    );
    is_deeply( $attribute->inflate( $obj, $json ),
        $test->{value}, 'inflation of ' . $attribute->name . ' works' );

}

done_testing;
