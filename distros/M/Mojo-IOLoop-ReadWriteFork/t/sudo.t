use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

$ENV{PATH} ||= '';
plan skip_all => './.sudo_password is missing' unless -r '.sudo_password';

my $fork     = Mojo::IOLoop::ReadWriteFork->new;
my $password = Mojo::Util::slurp('.sudo_password');
my $read     = '';
my ($exit_value, $signal);

chomp $password;

$fork->on(
  close => sub {
    ($exit_value, $signal) = @_[1, 2];
    Mojo::IOLoop->stop;
  }
);

$fork->on(
  read => sub {
    my ($fork, $chunk) = @_;
    $read .= $_[1];
    $fork->write("$password\n") if $read =~ s!password for.*:!!;
  }
);

$fork->start(program => 'sudo', program_args => [$^X, -e => q(print "hey $ENV{USER}!\n"; exit 3)], conduit => 'pty');

Mojo::IOLoop->timer(0.5 => sub { $fork->kill(9) });
Mojo::IOLoop->timer(1   => sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

like $read,     qr{hey root}, 'perl -e hey $USER';
is $exit_value, 3,            'exit_value';

done_testing;
