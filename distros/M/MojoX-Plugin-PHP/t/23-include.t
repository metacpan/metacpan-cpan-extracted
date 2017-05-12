use Test::More;
use Test::Mojo;
use strict;
use warnings;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is( 'This is t::MojoTestServer' );

# include.php: a script that only works if it can include other scripts
$t->get_ok('/include.php')->status_is(200,'include.php ok')
    ->content_like( qr/x is 625/ )
    ->content_like( qr/y is 343/ )
    ->content_like( qr/z is 64/ )
    # __FILE__ should be set correctly on all files
    ->content_like( qr/__FILE__ for include\.php.*include\.php/,
		    '__FILE__ set on main template' )
    ->content_like( qr/__FILE__ for include1\.php.*include1\.php/,
		    '__FILE__ set on included template in same dir')
    ->content_like( qr#__FILE__ for include2/include3\.php.*include2/include3\.php#,
		    '__FILE__ set on included template in subdirectory' )
    ->content_like( qr/__FILE__ for include4.*include4\.php/,
		    '__FILE__ set on included template with same dirname()');


done_testing();
