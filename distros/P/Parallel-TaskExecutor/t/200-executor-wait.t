use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Parallel::TaskExecutor;
use Test2::IPC;
use Test2::V0;

{
  my $e = Parallel::TaskExecutor->new();
  # We use this object so that the task blocks until after the Task is
  # destroyed.
  my $mosi = IO::Pipe->new();
  {
    my $t = $e->run(sub {
      $mosi->reader();
      $mosi->read(my $buf, 1);
      $mosi->close();
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
