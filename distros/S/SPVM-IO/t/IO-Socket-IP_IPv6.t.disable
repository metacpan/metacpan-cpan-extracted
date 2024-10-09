use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::IO::Socket::IP';

use Net::EmptyPort;
use Test::TCP;

unless (Net::EmptyPort::can_bind('::1')) {
  plan skip_all => "IPv6 not available"
}

use HTTP::Tiny;

use Mojolicious::Command::daemon;

my $server = Test::TCP->new(
  code => sub {
    my $port = shift;
    
    my $app = Mojo::Server->new->load_app('t/webapp/basic.pl');
    
    my $daemon_command = Mojolicious::Command::daemon->new(app => $app);
    
    my @args = ("--listen", "http://[::1]:$port");
    $daemon_command->run(@args);
    
    exit 0;
  },
  host => '::1',
);

my $port = $server->port;

ok(SPVM::TestCase::IO::Socket::IP->ipv6_basic($port));

ok(SPVM::TestCase::IO::Socket::IP->ipv6_set_blocking($port));

ok(SPVM::TestCase::IO::Socket::IP->ipv6_fileno($port));

ok(SPVM::TestCase::IO::Socket::IP->ipv6_goroutine($port));

done_testing;
