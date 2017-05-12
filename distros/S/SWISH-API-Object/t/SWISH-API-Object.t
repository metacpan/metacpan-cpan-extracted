use Test::More tests => 1;

SKIP: {

    eval { require SWISH::API };

    skip "SWISH::API is not installed - can't do More with it...", 1 if $@;

    skip "SWISH::API 0.04 or higher required", 1
        unless ( $SWISH::API::VERSION && $SWISH::API::VERSION ge 0.04 );

    require_ok('SWISH::API::Object');

    diag("testing SWISH::API::Object version $SWISH::API::Object::VERSION");

}

