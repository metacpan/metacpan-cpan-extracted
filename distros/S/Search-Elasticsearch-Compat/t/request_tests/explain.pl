#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $es_version );
my $r;

my %args = (
    index => 'es_test_1',
    type  => 'type_1',
    id    => 17,
);

SKIP: {
    skip "explain only supported in version 0.20", 26
        if $es_version lt '0.20';

    test_explain( 'good query', 1, { query => { term => { num => 18 } } } );
    test_explain( 'bad query',  0, { query => { term => { num => 17 } } } );
    test_explain( 'good queryb', 1, { queryb => { num => 18 } } );
    test_explain( 'bad queryb',  0, { queryb => { num => 17 } } );
    test_explain( 'good q',      1, { q      => "num:18" } );
    test_explain( 'bad q',       0, { q      => "num:17" } );

    test_explain(
        'all opts',
        1,
        {   q                        => "18",
            analyze_wildcard         => 1,
            analyzer                 => 'default',
            default_operator         => 'AND',
            df                       => 'num',
            fields                   => ['num'],
            lenient                  => 1,
            lowercase_expanded_terms => 1,
            preference               => '_local',
        }
    );

    is $r->{get}{fields}{num}, 18, ' - has fields';

    throws_ok { $es->explain( %args, routing => '18', q => 'num:18' ) }
    qr/Missing/, ' - doc not found';

    throws_ok { $es->explain( %args, query => 'foo', queryb => 'foo' ) }
    qr/Cannot specify/, ' - query and queryb';

    throws_ok { $es->explain( %args, q => 'foo', queryb => 'foo' ) }
    qr/Cannot specify/,
        ' - q and queryb';

    throws_ok { $es->explain( %args, q => 'foo', query => 'foo' ) }
    qr/Cannot specify/,
        ' - q and query';
}

sub test_explain {
    my ( $name, $match, $query ) = @_;
    ok $r = $es->explain( %args, %$query ), " - $name ok";
    is $r->{matched}, $match,
        $match ? " - $name matches" : " - $name doesn't match";
    ok $r->{explanation}, " - $name has explanation";
}

1;

