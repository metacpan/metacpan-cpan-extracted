#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Test::More;
use Punk::Test;

# The application is compiled once, at to_app, so a test that builds the app
# is testing the same frozen coderef the server runs - and one Punk::Test
# object is one browser: its cookie jar carries the session across every
# request below. See `perldoc Punk::Test` for the full assertion set.
chdir "$FindBin::Bin/.." or die "cannot chdir to the application root: $!\n";

my $t = Punk::Test->new('SSODemoIdP');

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/SSODemoIdP/, 'renders the welcome page');

$t->get_ok('/no-such-page')->status_is(404);

done_testing();
