use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $rwf = Mojo::IOLoop::ReadWriteFork->new;

subtest 'missing arguments' => sub {
  eval { $rwf->start({program_args => []}) };
  like $@, qr{program is required input}, 'program is required';
};

subtest 'invalid program' => sub {
  my ($exit_value, $signal);
  $rwf->on(finish => sub { ($exit_value, $signal) = @_[1, 2] });
  $rwf->run_p('__INVALID_PROGRAM_NAME_THAT_DOES_NOT_EXIST__')->wait;
  is $exit_value, 2, 'exit_value';
  is $signal,     0, 'signal';
};

done_testing;
