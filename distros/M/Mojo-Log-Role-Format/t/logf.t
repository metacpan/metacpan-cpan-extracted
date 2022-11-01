use Mojo::Base -strict;
use Mojo::Log;
use Test2::V0;

subtest normal => sub {
  my $log = make_logger();
  $log->$_("standard $_") for qw(debug warn);
  history_is($log, [[debug => 'standard debug'], [warn => 'standard warn']]);
};

subtest simple => sub {
  my $log = make_logger();
  $log->logf(info  => 'no format');
  $log->logf(error => 'format %s %.3f', 'cool', 42.1234567);
  history_is($log, [[info => 'no format'], [error => 'format cool 42.123']]);
};

subtest complex => sub {
  my $log = make_logger();
  $log->logf(info => 'not so deep %s', {foo => 42});
  $log->logf(warn => 'deeper %s',      {foo => {bar => 42}});
  history_is($log, [[info => 'not so deep {"foo":42}'], [warn => 'deeper {"foo":{"bar":42}}']]);
};

done_testing;

sub history_is {
  my ($log, $exp) = @_;
  my @history = map { [@$_[1, 2]] } @{$log->history};
  is \@history, $exp, 'logged';
}

sub make_logger {
  return Mojo::Log->with_roles('+Format')->new(handle => undef, level => 'debug');
}
