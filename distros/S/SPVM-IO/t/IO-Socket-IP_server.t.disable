use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::IO::Socket::IP';
use SPVM 'TestUtil';

use Test::SPVM::Sys::Socket::ServerManager::IP;

{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      SPVM::TestUtil->run_echo_server($port);
      
      exit 0;
    },
  );

  # IPv4
  {
    my $port = $server_manager->port;
    
    ok(SPVM::TestCase::IO::Socket::IP->server_ipv4_basic($port));
  }
}

# Repeat the same test to see for Windows.
{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      SPVM::TestUtil->run_echo_server($port);
      
      exit 0;
    },
  );
  
  # IPv4
  {
    my $port = $server_manager->port;
    
    ok(SPVM::TestCase::IO::Socket::IP->server_ipv4_basic($port));
  }
}

# with goroutine
{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      SPVM::TestUtil->run_echo_server_go($port);
      
      exit 0;
    },
  );
  
  # IPv4
  {
    my $port = $server_manager->port;
    
    ok(SPVM::TestCase::IO::Socket::IP->server_ipv4_basic($port));
    
    ok(SPVM::TestCase::IO::Socket::IP->server_ipv4_basic($port));
  }
}

done_testing;
