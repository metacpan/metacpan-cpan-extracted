package My::CanTrace;
use Test::More;
use POSIX ();

sub import {
  my $class = shift;

  my $ok = 0;
  for(qw(strace ktrace truss)) {
    system "$_ 2>/dev/null";
    $ok ||= POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?) == 1;
  }

  if($ok) {
    plan @_;
  } else {
    plan skip_all => "No tracing programs available";
  }
}

1;
