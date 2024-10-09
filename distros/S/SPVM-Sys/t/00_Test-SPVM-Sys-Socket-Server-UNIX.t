use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::SPVM::Sys::Socket::ServerManager::UNIX;
use Test::SPVM::Sys::Socket::Server;

{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::UNIX->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $path = $server_manager->path;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_unix_tcp(path => $path);
      
      $server->start;
    },
  );
}

ok(1);

done_testing;
