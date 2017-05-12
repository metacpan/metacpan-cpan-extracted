#!perl

use Test::Most;
use Env::Path;
use Net::NodeTransformator;
use Try::Tiny;
use File::Temp qw(tempdir);

plan skip_all => 'transformator is required for this test'
  unless Env::Path->PATH->Whence('transformator');

plan tests => 1;

my $client = Net::NodeTransformator->standalone;

try {
    is $client->jade( <<EOT, { name => 'Peter' } ) => '<span>Hi Peter!</span>';
span
  | Hi #{name}!
EOT
}
catch {
    diag $_
};

$client->cleanup;
