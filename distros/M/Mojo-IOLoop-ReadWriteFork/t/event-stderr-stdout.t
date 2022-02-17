use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

subtest 'stderr=1' => sub {
  my ($fork, $stdout, $stderr) = rwf();
  $fork->conduit->{stderr} = 1;
  $fork->run_p(\&run_cb)->wait;
  is $$stdout, '', 'stdout closed';
  like $$stderr, qr{Not cool}, 'stderr';
};

subtest 'stderr=1, stdout=1' => sub {
  my ($fork, $stdout, $stderr) = rwf();
  $fork->conduit->{stderr} = 1;
  $fork->conduit->{stdout} = 1;
  $fork->run_p(\&run_cb)->wait;
  is $$stdout, "cool beans\n", 'stdout';
  like $$stderr, qr{Not cool}, 'stderr';
};

done_testing;

sub run_cb {
  print STDOUT "cool beans\n";
  die 'Not cool';
}

sub rwf {
  my $fork = Mojo::IOLoop::ReadWriteFork->new;
  my ($stdout, $stderr) = ('', '');
  $fork->on(stderr => sub { $stderr .= $_[1] });
  $fork->on(stdout => sub { $stdout .= $_[1] });

  return $fork, \$stdout, \$stderr;
}
