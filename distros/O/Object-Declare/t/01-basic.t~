use strict;
use Test::More tests => 3, import => ['is_deeply'];
use ok 'Object::Declare' => 
    copula => {
        is  => '',
        are => 'plural_',
    },
    aliases => {
        field2 => 'fun',
    },
    mapping => {
        column  => 'MyApp::Column',
        alt_col => sub { return { alt => column(), @_ } }
    };

sub column { 1 }

sub MyApp::Column::new { shift; return { @_ } }

sub do_declare { declare {
    column x =>
        is rw,
        is Very::Happy,
        field1 is 'xxx',
        field2 are 'XXX', 'XXX',
        is field3,
        parts are column( is happy ), column( !is happy );

    alt_col y =>
        !is Very::Happy,
        field1 is 'yyy',
        field2 is 'YYY',
        col is column( is happy );
} }

my @objects = do_declare;

is_deeply(\@objects => [
    x => {
            'name' => 'x',
            'field1' => 'xxx',
            'plural_field2' => ['XXX', 'XXX'],
            'plural_parts' =>[ { happy => 1 },{ happy => '' },],
            'field3' => 1,
            'rw' => 1,
            'Very::Happy' => 1,
            },
    y => {
            'name' => 'y',
            'field1' => 'yyy',
            'fun' => 'YYY',
            'alt'    => 1,
            col      => {
                          'name' => 'col',
                          'happy' => 1,
                        },
            'Very::Happy' => '',
            },
], 'object declared correctly (list context)');

my $objects = do_declare;

is_deeply($objects => {
    x => {
            'name' => 'x',
            'field1' => 'xxx',
            'plural_field2' => ['XXX', 'XXX'],
            'plural_parts' =>[ {happy => 1},{happy => ''},],
            'field3' => 1,
            'rw' => 1,
            'Very::Happy' => 1,
            },
    y => {
            'name' => 'y',
            'field1' => 'yyy',
            'fun' => 'YYY',
            'alt'    => 1,
            col      => {
                          'name' => 'col',
                          'happy' => 1,
                        },
            'Very::Happy' => '',
            },
}, 'object declared correctly (scalar context)');

