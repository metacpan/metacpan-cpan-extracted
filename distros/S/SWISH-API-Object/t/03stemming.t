use Test::More tests => 4;

SKIP: {

    eval { require SWISH::API };

    skip "SWISH::API is not installed - can't do More with it...", 4
        if $@;

    skip "SWISH::API 0.04 or higher required", 4
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

    ok( my $fuzzy_word = $swish->fuzzify( $index, 'running' ),
        "get fuzzy_word" );

    #diag( $fuzzy_word->word_error );

    is( ( $fuzzy_word->word_list )[0], 'run', "stemmed running => run" );

}
