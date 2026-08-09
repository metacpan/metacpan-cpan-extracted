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

# Open::API::UI needs perl 5.010 (defined-or) plus Template::Stencil 0.02
# and Markdown::Simple 0.18 - recommends, not prereqs, so neither is
# guaranteed to be there and neither is guaranteed to be new enough: a
# recommendation cannot upgrade a machine that already has an older copy.
# The versions are part of the guard for that reason.
SKIP: {
    skip 'Open::API::UI needs perl 5.010', 1 if $] < 5.010;
    skip 'Template::Stencil 0.02+ and Markdown::Simple 0.18+ not available', 1
        unless eval { require Template::Stencil;
                      Template::Stencil->VERSION('0.02');
                      require Markdown::Simple;
                      Markdown::Simple->VERSION('0.18'); 1 };
    require_ok( 'Open::API::UI' );
}

diag( "Testing Open::API $Open::API::VERSION, Perl $], $^X" );

done_testing();
