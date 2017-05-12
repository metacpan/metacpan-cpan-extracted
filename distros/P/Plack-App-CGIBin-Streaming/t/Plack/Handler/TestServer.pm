package Plack::Handler::TestServer;

use strict;
use warnings;
use parent 'Plack::Handler::Starman';

sub run {
    my ($self, $app)=@_;

    My::Server->new->run($app, +{
                                 workers=>1,
                                 error_log=>'error_log',
                                 %$self,
                                });
}

package My::Server;

use strict;
use warnings;
use parent 'Starman::Server';

sub log {}

1;
