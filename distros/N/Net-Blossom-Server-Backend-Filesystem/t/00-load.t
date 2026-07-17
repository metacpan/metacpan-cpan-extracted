use strictures 2;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib";

use_ok('Net::Blossom::Server::Backend::Filesystem');
use_ok('Net::Blossom::Server::Backend::Filesystem::BlobStore');

is($Net::Blossom::Server::Backend::Filesystem::VERSION, '0.001001',
    'distribution version is declared');

done_testing;
