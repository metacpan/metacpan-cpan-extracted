use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};
plan skip_all => 'cat is missing'  unless grep { -x "$_/cat" } split /:/,  $ENV{PATH};

subtest 'pipe' => sub {
  my $rwf = Mojo::IOLoop::ReadWriteFork->new->conduit({type => 'pipe'});
  my ($err, $exit_value);
  $rwf->on(spawn => sub { $rwf->close('stdin') });
  $rwf->run_p(qw(cat -))->then(sub { $exit_value = shift }, sub { $err = shift })->wait;
  is $err || $exit_value, 0, 'success';
};

subtest 'pty' => sub {
  my $rwf = Mojo::IOLoop::ReadWriteFork->new->conduit({type => 'pty'});
  my ($err, $exit_value);
  $rwf->on(spawn => sub { $rwf->close('stdin') });
  $rwf->run_p(qw(bash))->then(sub { $exit_value = shift }, sub { $err = shift })->wait;
  is $err || $exit_value, 0, 'success';
};

subtest 'pty3' => sub {
  my $rwf = Mojo::IOLoop::ReadWriteFork->new->conduit({type => 'pty3'});
  my ($err, $exit_value);
  $rwf->on(spawn => sub { $rwf->close('stdin') });
  $rwf->run_p(qw(bash))->then(sub { $exit_value = shift }, sub { $err = shift })->wait;
  is $err || $exit_value, 0, 'success';
};

done_testing;
