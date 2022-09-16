BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::Run3;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_SSH=hostname' unless $ENV{TEST_SSH};

subtest 'close other' => sub {
  my $run3 = Mojo::Run3->new(driver => 'pty');
  my %read = (stderr => '', stdout => '');
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->on(pty    => sub { $read{pty}    .= $_[1]; $read{pty} =~ m!password!i && shift->close('stdin') });

  $run3->run_p(sub {
    my ($run3) = @_;
    $run3->close('other');
    exec ssh => qw(-t -o PreferredAuthentications=password) => $ENV{TEST_SSH};
    die $!;
  })->wait;

  like $read{pty}, qr{password:}, 'got pty';
};

done_testing;
