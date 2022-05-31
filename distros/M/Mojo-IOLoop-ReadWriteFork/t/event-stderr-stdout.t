use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

subtest 'stderr=1' => sub {
  my ($rwf, $stdout, $stderr) = rwf();
  $rwf->conduit->{stderr} = 1;
  $rwf->run_p(\&run_cb)->wait;
  is $$stdout, '', 'stdout closed';
  like $$stderr, qr{Not cool}, 'stderr';
};

subtest 'stderr=1, stdout=1' => sub {
  my ($rwf, $stdout, $stderr) = rwf();
  $rwf->conduit->{stderr} = 1;
  $rwf->conduit->{stdout} = 1;
  $rwf->run_p(\&run_cb)->wait;
  is $$stdout, "cool beans\n", 'stdout';
  like $$stderr, qr{Not cool}, 'stderr';
};

done_testing;

sub run_cb {
  print STDOUT "cool beans\n";
  die 'Not cool';
}

sub rwf {
  my $rwf = Mojo::IOLoop::ReadWriteFork->new;
  my ($stdout, $stderr) = ('', '');
  $rwf->on(stderr => sub { $stderr .= $_[1] });
  $rwf->on(stdout => sub { $stdout .= $_[1] });

  return $rwf, \$stdout, \$stderr;
}
