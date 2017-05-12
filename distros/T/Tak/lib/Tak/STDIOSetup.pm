package Tak::STDIOSetup;

use Log::Contextual qw(:log);
use Log::Contextual::SimpleLogger;
use Tak::ConnectionService;
use Tak::Router;
use Tak;
use IO::Handle;
use strictures 1;

sub run {
  open my $stdin, '<&', \*STDIN or die "Duping stdin: $!";
  open my $stdout, '>&', \*STDOUT or die "Duping stdout: $!";
  $stdout->autoflush(1);
  # if we don't re-open them then 0 and 1 get re-used - which is not
  # only potentially bloody confusing but results in warnings like:
  # "Filehandle STDOUT reopened as STDIN only for input"
  close STDIN or die "Closing stdin: $!";
  open STDIN, '<', '/dev/null' or die "Re-opening stdin: $!";
  close STDOUT or die "Closing stdout: $!";
  open STDOUT, '>', '/dev/null' or die "Re-opening stdout: $!";
  my ($host, $level) = @ARGV;
  my $sig = '<'.join ':', $host, $$.'> ';
  Log::Contextual::set_logger(
    Log::Contextual::SimpleLogger->new({
      levels_upto => $level,
      coderef => sub { print STDERR $sig, @_; }
    })
  );
  my $done;
  my $connection = Tak::ConnectionService->new(
    read_fh => $stdin, write_fh => $stdout,
    listening_service => Tak::Router->new,
    on_close => sub { $done = 1 }
  );
  $connection->receiver->service->register_weak(remote => $connection);
  $0 = 'tak-stdio-node';
  log_debug { "Node starting" };
  # Tell the other end that we've finished messing around with file
  # descriptors and that it's therefore safe to start sending requests.
  print $stdout "Shere\n";
  Tak->loop_until($done);
  if (our $Next) { goto &$Next }
}

1;
