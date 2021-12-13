package Mojo::IOLoop::ReadWriteProcess::Test::Utils;

our @EXPORT_OK = qw(attempt);
use Time::HiRes qw(sleep);
use Exporter 'import';
use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

sub attempt {
  my $attempts = 0;
  my ($total_attempts, $condition, $cb, $or)
    = ref $_[0] eq 'HASH' ? (@{$_[0]}{qw(attempts condition cb or)}) : @_;
  $cb //= sub {1};
  until ($condition->() || $attempts >= $total_attempts) {
    warn "Attempt $attempts" if DEBUG;
    $cb->();
    sleep .1;
    $attempts++;
  }
  $or->()                     if $or && !$condition->();
  warn "Attempts terminated!" if DEBUG;
}


1;
