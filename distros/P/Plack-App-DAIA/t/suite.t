use strict;
use warnings;

use Test::More;
use Plack::App::DAIA::Test::Suite;

my $app = './app.psgi';

provedaia( 't/docid.json', server => $app, ids => [ 'foo:bar' ] );

provedaia <<SUITE, server => $app;
foo:bar

# document expected
{ "document" : [ { } ] }
SUITE

provedaia $app, server => $app, end => 1;

done_testing;
