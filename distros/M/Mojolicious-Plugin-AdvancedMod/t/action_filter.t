use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new( 'MyApp' );

# After
$t->get_ok('/')->content_like(qr/check_permissions filter/);

# Before
$t->get_ok('/show')->content_like(qr/is_auth filter/);

done_testing();