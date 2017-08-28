use Mojo::Base -strict;
use Mojo::File 'path';
use Mojolicious::Command::openapi;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my @said;
Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _say => sub { push @said, @_ });

my $cmd = Mojolicious::Command::openapi->new;
$cmd->run('http://petstore.swagger.io/v2/swagger.json', 'getInventory');
like "@said", qr{Available}, 'getInventory';

done_testing;
