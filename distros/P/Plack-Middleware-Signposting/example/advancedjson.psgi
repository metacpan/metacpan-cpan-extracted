# plackup -p 5001 -I lib/ example/advancedjson.psgi
# curl -I http://localhost:5001/

use strict;
use warnings;
use Plack::Builder;
use File::Slurp;
use FindBin qw($Bin);

my $json = read_file("$Bin/publication.json");
my $app = sub {
    [200, ['Content-Type' => 'application/json'], [$json]];
};

builder {
   enable "Plack::Middleware::Signposting::JSON", fix => 'example/signposting.fix';
   $app;
};
