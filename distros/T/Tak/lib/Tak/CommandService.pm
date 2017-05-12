package Tak::CommandService;

use Capture::Tiny qw(capture);
use IPC::System::Simple qw(runx EXIT_ANY);
use IPC::Open3;
use Symbol qw(gensym);
use Moo;

with 'Tak::Role::Service';

sub handle_exec {
  my ($self, $command) = @_;
  my $code;
  my ($stdout, $stderr) = capture {
    $code = runx(EXIT_ANY, @$command);
  };
  return { stdout => $stdout, stderr => $stderr, exit_code => $code };
}

sub start_stream_exec_request {
  my ($self, $req, $command) = @_;
  my $err = gensym;
  my $pid = open3(my $in, my $out, $err, @$command)
    or return $req->failure("Couldn't spawn process: $!");
  close($in); # bye
  my $done = sub {
    Tak->loop->unwatch_io(handle => $_, on_read_ready => 1)
      for ($out, $err);
    waitpid($pid, 0);
    $req->success({ exit_code => $? });
  };
  my $outbuf = '';
  my $errbuf = '';
  Tak->loop->watch_io(
    handle => $out,
    on_read_ready => sub {
      if (sysread($out, $outbuf, 1024, length($outbuf)) > 0) {
        $req->progress(stdout => $1) while $outbuf =~ s/^(.*)\n//;
      } else {
        $req->progress(stdout => $outbuf) if $outbuf;
        $req->progress(stderr => $errbuf) if $errbuf;
        $done->();
      }
    }
  );
  Tak->loop->watch_io(
    handle => $err,
    on_read_ready => sub {
      if (sysread($err, $errbuf, 1024, length($errbuf)) > 0) {
        $req->progress(stderr => $1) while $errbuf =~ s/^(.*)\n//;
      }
    }
  );
}

1;
