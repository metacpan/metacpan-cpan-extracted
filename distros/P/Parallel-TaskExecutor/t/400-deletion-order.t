use strict;
use warnings;
use utf8;

use FindBin;
use IO::Pipe;
use Log::Log4perl::CommandLine ':all';
use Parallel::TaskExecutor;
use Test2::IPC;
use Test2::V0;

my $log = Log::Log4perl->get_logger();

{
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
  }
  pass('~task done ~executor');
}

{
  {
    # We use this object so that the task blocks until after the Task is
    # destroyed.
    my $t;
    my $mosi = IO::Pipe->new();
    {
      my $e = Parallel::TaskExecutor->new();
      $t = $e->run(sub {
        $mosi->reader();
        $mosi->read(my $buf, 1);
        $mosi->close();
      });
    }
    $mosi->writer();
    $mosi->write("GO");
    $mosi->close();
  }
  pass('~executor done ~task');
}

{
  {
    my $e = Parallel::TaskExecutor->new();
    {
      my $t = $e->run(sub { return 1 });
      $t->wait();
    }
  }
  pass('done ~task ~executor');
}

{
  {
    my $t;
    {
      my $e = Parallel::TaskExecutor->new();
      $t = $e->run(sub { return 1 });
      $t->wait();
    }
  }
  pass('done ~executor ~task');
}

done_testing;
