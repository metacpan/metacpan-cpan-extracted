use Test::More tests => 12;

use File::Spec;
use Carp;
use Data::Dump qw( dump );

SKIP: {

    eval { require SWISH::API };

    skip "SWISH::API is not installed - can't do More with it...", 12 if $@;

    skip "SWISH::API 0.04 or higher required", 12
        unless ( $SWISH::API::VERSION && $SWISH::API::VERSION ge 0.04 );

    require_ok('SWISH::API::Object');

    my $index = File::Spec->catfile( 't', 'index.swish-e' );
    my $files = join( ' ',
        File::Spec->catfile( 't', 'test.html' ),
        File::Spec->catfile( 't', 'json.html' ),
        File::Spec->catfile( 't', 'yaml.html' ) );
    my $config = File::Spec->catfile( 't', 'conf' );
    my $cmd = "swish-e -i $files -f $index -c $config";

    diag($cmd);
    system($cmd);

    unless ( -s $index ) {
        skip 'no index found', 11;
    }

    ok( my $swish = SWISH::API::Object->new(
            indexes => [$index],
            class   => 'My::Class'
        ),
        "new object"
    );

    #diag(dump($swish));

    ok( my $results = $swish->query('yaml'), "query" );

    #diag(dump($results));

    while ( my $object = $results->next_result ) {

        #diag '-' x 60;
        #diag(dump $object);
        for my $prop ( $swish->props ) {
            ok( printf( "%s = %s\n", $prop, $object->$prop ),
                "property printed" );
        }
    }

}
