use Test::More tests => 13;

SKIP: {

    eval { require SWISH::API };

    skip "SWISH::API is not installed - can't do More with it...", 13 if $@;

    skip "SWISH::API 0.04 or higher required", 13
        unless ( $SWISH::API::VERSION && $SWISH::API::VERSION ge 0.04 );

    require_ok('SWISH::API::Object');

    use Carp;
    use Data::Dump qw( dump );

    my $index = File::Spec->catfile( 't', 'index.swish-e' );

    ok( my $swish = SWISH::API::Object->new(
            indexes       => [$index],
            class         => 'My::Class',
            serial_format => 'json'
        ),
        "new object"
    );

    #diag(dump($swish));

    ok( my $results = $swish->query('json'), "query" );

    is_deeply( ['json'],
        [ $results->parsed_words( $results->base->indexes->[0] ) ],
        "parsed_words()" );

    while ( my $object = $results->next_result ) {

        #diag '-' x 60;
        #diag(dump $object);
        for my $prop ( $swish->props ) {
            ok( printf( "%s = %s\n", $prop, $object->$prop ),
                "property printed" );
        }
    }

}
