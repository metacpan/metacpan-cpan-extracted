#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;


BEGIN {
    plan tests => 4;

    use_ok( 'MojoX::Plugin::PHP' ) || print "Bail out!\n";
    use_ok( 'MojoX::Template::PHP' ) || print "Bail out!\n";
}
require_ok( 'Mojolicious' );
require_ok( 'PHP' );

diag( "\nTesting MojoX::Plugin::PHP $MojoX::Plugin::PHP::VERSION" );
diag( "\tPerl $], $^X" );
diag( "\tMojolicious version $Mojolicious::VERSION" );
diag( "\tp5-php version $PHP::VERSION" );

