package Object::Remote::Connector::STDIO;

use File::Spec;
use IO::Handle;
use Object::Remote::Connection;
use Object::Remote::ReadChannel;
use Moo;

sub connect {
  open my $stdin, '<&', \*STDIN or die "Duping stdin: $!";
  open my $stdout, '>&', \*STDOUT or die "Duping stdout: $!";
  $stdout->autoflush(1);
  # if we don't re-open them then 0 and 1 get re-used - which is not
  # only potentially bloody confusing but results in warnings like:
  # "Filehandle STDOUT reopened as STDIN only for input"
  close STDIN or die "Closing stdin: $!";
  open STDIN, '<', File::Spec->devnull or die "Re-opening stdin: $!";
  close STDOUT or die "Closing stdout: $!";
  open STDOUT, '>', File::Spec->devnull or die "Re-opening stdout: $!";
  return Object::Remote::Connection->new(
    send_to_fh => $stdout,
    read_channel => Object::Remote::ReadChannel->new(fh => $stdin)
  );
}

1;
