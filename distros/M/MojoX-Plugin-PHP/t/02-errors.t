use Test::More;
use Test::Mojo;
use Data::Dumper;
use strict;
use warnings;

$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is('This is t::MojoTestServer');


$t->get_ok('/not_found.php')->status_is(404);
$t->get_ok('/compile-error.php')->status_is(500)
    ->content_like( qr/PHP Parse error:\s+syntax error/ );

# a runtime error is not a server error
$t->get_ok('/runtime-error.php')->status_is(200);


done_testing();
