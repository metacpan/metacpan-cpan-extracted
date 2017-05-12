use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Mojolicious::Quick;

my $app = Mojolicious::Quick->new();
can_ok( $app, 'routes' );
isa_ok( $app->routes, 'Mojolicious::Routes' );

done_testing;
