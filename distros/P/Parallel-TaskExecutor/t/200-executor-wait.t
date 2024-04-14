use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Log::Log4perl::CommandLine ':all', ':loginit' => {layout => "[%p] %m (%c)%n" };
use Parallel::TaskExecutor;
use Test2::V0;

# TODO: Remove this line once the following issue is fixe:
# https://github.com/Test-More/test-more/issues/928
Test2::API::test2_load if $^O eq 'MSWin32';

my $log = Log::Log4perl->get_logger();

{
  my $e = Parallel::TaskExecutor->new();
  # We use this object so that the task blocks until after the Task is
  # destroyed.
  my $mosi = IO::Pipe->new();
  {
    my $t = $e->run(sub {
      $mosi->reader();
      $log->trace("zombie started");
      $mosi->read(my $buf, 1);
      $log->trace("zombie unblocked");
      $mosi->close();
      $log->trace("zombie done");
    });
  }
  $mosi->writer();
  $mosi->write("GO");
  $mosi->close();
  $e->wait();
  pass('wait does not block with zombie tasks');
}

{
  my $e = Parallel::TaskExecutor->new();
  my $t = $e->run(sub { return 1 });
  $e->wait();
  pass('wait does not block with non-zombie tasks');
}

done_testing;
