use Mojo::Base -strict;
use Mojo::Run3;
use Test::More;

subtest 'die' => sub {
  my $run3 = Mojo::Run3->new;
  my ($stderr, $stdout) = ('', '');
  $run3->on(stderr => sub { $stderr .= $_[1] });
  $run3->on(stdout => sub { $stdout .= $_[1] });
  $run3->run_p(sub { die 'not cool' })->wait;
  chomp $stderr;
  like $stderr, qr{not cool}, "stderr $stderr";
  is $stdout,            '',  'stdout';
  is $run3->exit_status, 255, 'status';
};

subtest 'invalid command' => sub {
  my $run3 = Mojo::Run3->new;
  my ($stderr, $stdout) = ('', '');
  $run3->on(stderr => sub { $stderr .= $_[1] });
  $run3->on(stdout => sub { $stdout .= $_[1] });
  $run3->run_p(sub { exec '/no/such/command' })->wait;
  chomp $stderr;
  like $stderr, qr{Can't exec}, "stderr $stderr";
  is $stdout,            '', 'stdout';
  is $run3->exit_status, 2,  'status';
};

done_testing;
