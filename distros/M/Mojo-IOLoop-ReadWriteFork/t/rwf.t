use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $fork = Mojo::IOLoop::ReadWriteFork->new;

subtest 'missing arguments' => sub {
  eval { $fork->start({program_args => []}) };
  like $@, qr{program is required input}, 'program is required';
};

subtest 'invalid program' => sub {
  my ($exit_value, $signal);
  $fork->on(finish => sub { ($exit_value, $signal) = @_[1, 2] });
  $fork->run_p('__INVALID_PROGRAM_NAME_THAT_DOES_NOT_EXIST__')->wait;
  is $exit_value, 2, 'exit_value';
  is $signal,     0, 'signal';
};

done_testing;
