#!/usr/bin/env perl 
use strict;
use warnings;
use Search::Query;
use Test::More tests => 7;
use Data::Dump qw( dump );
use Try::Tiny;

{

    package MyField;
    use Moo;
    extends 'Search::Query::Field';

    sub validate {
        my $self  = shift;
        my $value = shift;
        if ( $value eq 'bad' ) {
            $self->error('bad value');
            return 0;
        }
        return 1;
    }

}

ok( my $parser = Search::Query->parser(
        field_class    => 'MyField',
        fields         => ['somefield'],
        croak_on_error => 1,
    ),
    "new parser with field_class"
);

ok( my $query = $parser->parse('somefield:foo OR bar'), 'parse query' );

try {
    $parser->parse('somefield:bad');
    fail('bad field value ignored');
}
catch {
    like(
        $_,
        qr/Invalid field value for somefield/,
        'got exception for bad field value'
    );
};

# dialect defined field class
ok( my $dialect_parser = Search::Query->parser(
        dialect        => 'SWISH',
        fields         => ['somefield'],
        croak_on_error => 1,
    ),
    'SWISH dialect parser'
);
is( $dialect_parser->field_class,
    'Search::Query::Field::SWISH', 'inherits field class from dialect' );

ok( my $custom_field_parser = Search::Query->parser(
        dialect        => 'SWISH',
        fields         => ['somefield'],
        croak_on_error => 1,
        field_class    => 'MyField'
    ),
    'custom field parser'
);
is( $custom_field_parser->field_class,
    'MyField', 'custom field clas override' );
