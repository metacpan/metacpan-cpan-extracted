package Mojo::IOLoop::ReadWriteProcess::Test::Utils;

our @EXPORT_OK = qw(attempt check_bin);
use Time::HiRes qw(sleep);
use Exporter 'import';
use Test::More;
use Mojo::File qw(path);
use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

sub attempt {
  my $attempts = 0;
  my ($total_attempts, $condition, $cb, $or)
    = ref $_[0] eq 'HASH' ? (@{$_[0]}{qw(attempts condition cb or)}) : @_;
  $cb //= sub { 1 };
  until ($condition->() || $attempts >= $total_attempts) {
    warn "Attempt $attempts" if DEBUG;
    $cb->();
    sleep .1;
    $attempts++;
  }
  $or->()                     if $or && !$condition->();
  warn "Attempts terminated!" if DEBUG;
}

sub check_bin {
  my $script = shift;

  plan skip_all =>
    "You do not seem to have $script. The script is required to run the test"
    unless -e $script;

  if (-T $script) {
    my ($shebang) = path($script)->slurp =~ m/^#!(\S+)/;
    plan skip_all =>
      "You do not seem to have $shebang wich is required for $script"
      if ($shebang && !-e $shebang);
  }
  return $script;
}

1;
