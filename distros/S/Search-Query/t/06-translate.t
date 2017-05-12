use strict;
use warnings;
use Test::More tests => 6;
use Data::Dump qw( dump );

use_ok('Search::Query::Parser');

ok( my $parser = Search::Query::Parser->new(
        fields         => [qw( foo color name )],
        default_field  => 'name',
        dialect        => 'SQL',
        croak_on_error => 1,
    ),
    "new parser"
);

ok( my $sql_query = $parser->parse('foo=bar or (name=fred and color=red)'),
    "query" );

ok( my $swish_query = $sql_query->translate_to('SWISH'),
    "translate_to SWISH" );

is_deeply( $sql_query->tree, $swish_query->tree, "cmp_deeply trees" );
ok( $swish_query->isa('Search::Query::Dialect::SWISH'), "SWISH isa SWISH" );

#diag( dump($sql_query) );
#diag( dump($swish_query) );
