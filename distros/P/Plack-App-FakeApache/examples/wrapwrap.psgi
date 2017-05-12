#
# Plack::Handler::Apache2 is a great example of a mod_perl2 application. This
# shows how to turn it into a Plack application. We are selfhosting!
#

use strict;
use warnings;

use Plack::App::FakeApache;

Plack::App::FakeApache->new(
    handler    => 'Plack::Handler::Apache2',
    dir_config => {
        psgi_app => 'simple.psgi',
    }
)->to_app;
