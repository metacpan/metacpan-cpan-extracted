use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;
use Time::HiRes qw(sleep);

subtest 'close stderr from child' => sub {
  my $run3 = Mojo::Run3->new;
  my $read = 0;
  $run3->on(stdout => sub { $read += length $_[1] });
  $run3->run_p(sub { close STDERR; sleep 0.2; $! = 0; print +('x' x 10_000_000), "\n" })->wait;
  is $read,         10_000_001, 'read';
  is $run3->status, 0,          'status';
};

subtest 'close stdout from child' => sub {
  my $run3 = Mojo::Run3->new;
  my %read;
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->run_p(sub { close STDOUT; print +('x' x 10_000_000), "\n" })->wait;
  is $read{stdout}, undef, 'stdout';
  like $read{stderr}, qr{closed filehandle}, 'stderr';
  is $run3->exit_status, 9, 'exit_status';
};

subtest 'close stdout from parent' => sub {
  my $run3 = Mojo::Run3->new;
  my %read;
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });
  $run3->on(spawn  => sub { shift->close('stdout') });

  $run3->run_p(sub {
    sleep 0.1;
    print STDERR "not closed\n";
    system $^X => -e => 'print STDOUT 123; exit $!';
    exit $?;
  })->wait;

  is $read{stdout}, undef, 'stdout';
  like $read{stderr}, qr{not closed}, 'stderr';
  is $run3->exit_status, 13, 'exit_status';
};

subtest 'close other' => sub {
  my $run3 = Mojo::Run3->new;
  my %read = (stderr => '', stdout => '');
  $run3->on(stderr => sub { $read{stderr} .= $_[1] });
  $run3->on(stdout => sub { $read{stdout} .= $_[1] });

  eval { $run3->close('other') };
  like $@, qr{Cannot close 'other'}, 'close other in parent';

  open my $CLOSE_ME, '<', __FILE__;
  $run3->run_p(sub {
    my ($run3) = @_;
    printf STDERR "%s\n", int grep { open my $FH, '<&=', $_ } 0 .. (Mojo::Run3->MAX_OPEN_FDS - 1);
    $run3->close('other');
    printf STDOUT "%s\n", int grep { open my $FH, '<&=', $_ } 0 .. (Mojo::Run3->MAX_OPEN_FDS - 1);
  })->wait;

  ok $read{stderr} > $read{stdout}, 'before close other';
  like $read{stdout}, qr{^3\b}, 'after close other';
};

done_testing;
