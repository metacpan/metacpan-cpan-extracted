#!/usr/bin/perl

use Test::More tests => 14;

use Syndication::ESF;

my $testdata = {
    channel => {
        title   => 'test title',
        contact => 'test contact',
        link    => 'test link'
    },
    items => [
        {   date  => time,
            title => 'test title',
            link  => 'test link'
        },
        {   date  => time,
            title => 'test title 2',
            link  => 'test link 2'
        },
    ]
};

my @channel_fields = qw( title contact link );
my @item_fields    = qw( date title link );

my $esf = Syndication::ESF->new;

ok( defined $esf,                    "new() returned something" );
ok( $esf->isa( 'Syndication::ESF' ), "it's the right class" );

$esf->channel( %{ $testdata->{ channel } } );

for ( @channel_fields ) {
    is( $esf->channel( $_ ),
        $testdata->{ channel }->{ $_ },
        "channel( '$_' ) matches test data"
    );
}
is( scalar @{ $esf->add_item( %{ $testdata->{ items }->[ 0 ] } ) },
    1, "additem( [data] )" );

for ( @item_fields ) {
    is( $esf->{ items }->[ 0 ]->{ $_ },
        $testdata->{ items }->[ 0 ]->{ $_ },
        "{ items }->[0]->{ $_ } matches test data"
    );
}

is( scalar @{
        $esf->add_item( %{ $testdata->{ items }->[ 1 ] }, mode => 'insert' )
        },
    2,
    "additem( [data], mode => 'insert' )"
);

for ( @item_fields ) {
    is( $esf->{ items }->[ 0 ]->{ $_ },
        $testdata->{ items }->[ 1 ]->{ $_ },
        "{ items }->[0]->{ $_ } matches test data"
    );
}

$esf->save( 't/test2.esf' );

like( -s 't/test2.esf', qr/(122|128)/, "save( 'test2.esf' )" );

unlink( 't/test2.esf' );
