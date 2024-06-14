use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use Test::TCP;

use SPVM ();
use SPVM 'Int';
use SPVM 'Sys';
use SPVM 'Sys::IO::Constant';
use SPVM 'Sys::OS';
use SPVM 'HTTP::Tiny';

# Close SPVM's stdout and stderr
# If not, "make test" (Test::Harness->runtests) waits forever,
unless (SPVM::Sys::OS->is_windows) {
  SPVM::Sys->fcntl(SPVM::Sys->fileno(SPVM::Sys->STDOUT), SPVM::Sys::IO::Constant->F_SETFD, SPVM::Int->new(SPVM::Sys::IO::Constant->FD_CLOEXEC));
  SPVM::Sys->fcntl(SPVM::Sys->fileno(SPVM::Sys->STDERR), SPVM::Sys::IO::Constant->F_SETFD, SPVM::Int->new(SPVM::Sys::IO::Constant->FD_CLOEXEC));
}

my $server = Test::TCP->new(
  code => sub {
    my $port = shift;
    
    # Throw way stdout and stderr
    # If not, "make test" (Test::Harness->runtests) waits forever,
    my $cmd = "perl t/webapp/basic.pl daemon --listen http://*:$port >/dev/null 2>&1";
    
    warn "[Test Output]Server port:$port";
    
    exec($cmd);
    
    die "exec failed.";
  },
);

my $http = SPVM::HTTP::Tiny->new;

my $port = $server->port;

my $res = $http->get("http://127.0.0.1:$port/hello");

like($res->content, qr|Hello|);

done_testing;
