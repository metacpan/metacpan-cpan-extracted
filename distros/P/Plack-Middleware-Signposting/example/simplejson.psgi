# plackup -p 5001 -I lib/ example/simplejson.psgi
# curl -I http://localhost:5001/

use strict;
use warnings;
use Plack::Builder;

my $app = sub {
    [200, ['Content-Type' => 'application/json'], ['{"name":"Fu Manchu", "orcid":"12345-im-an-orcid"}']];
};

builder {
   enable "Plack::Middleware::Signposting::JSON";
   $app;
};
