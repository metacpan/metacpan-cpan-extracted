use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;

my ($bash) = grep { -x "$_/bash" } split /:/, $ENV{PATH} || '';
plan skip_all => 'bash was not found' unless $bash;

subtest 'bash' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  $run3->ioloop->timer(2 => sub { $run3->close('stdin')->kill(9) });

  my ($sent, %read);
  $run3->on(pty    => sub { $read{pty}    .= $_[1] });
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->write("echo cool beans && exit\n");
  $run3->run_p(sub { exec qw(bash -i) })->wait;
  ok $run3->pid > 0, 'pid';
  like $read{stdout}, qr{cool beans\n$}m, 'stdout';
};

subtest 'close stdin' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  $run3->ioloop->timer(2 => sub { $run3->kill(9) });

  $run3->on(
    spawn => sub {
      my ($run3) = @_;
      ok $run3->handle('pty'), 'got pty';
      $run3->close('stdin');
      ok !$run3->handle('pty'), 'close stdin also close pty';
    }
  );

  $run3->run_p(sub { exec qw(bash -i) })->wait;
  ok $run3->pid > 0, 'pid';
};

done_testing;
