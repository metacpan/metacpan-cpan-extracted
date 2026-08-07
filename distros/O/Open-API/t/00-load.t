#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Open::API' ) || print "Bail out!\n";
    use_ok( 'Open::API::Plack' );
    use_ok( 'Open::API::Client' );
}

# Loading at all means BOOT resolved JSON::Schema::Fast's C ABI (the .pm
# croaks otherwise); assert it explicitly too.
ok( Open::API::_abi_ok(), 'JSON::Schema::Fast C ABI resolved' );

# Open::API::UI needs perl 5.16 plus Template::Stencil and
# Markdown::Simple (recommends, not prereqs).
SKIP: {
    skip 'Open::API::UI needs perl 5.16', 1 if $] < 5.016;
    skip 'Template::Stencil and Markdown::Simple not available', 1
        unless eval { require Template::Stencil;
                      require Markdown::Simple; 1 };
    require_ok( 'Open::API::UI' );
}

diag( "Testing Open::API $Open::API::VERSION, Perl $], $^X" );

done_testing();
