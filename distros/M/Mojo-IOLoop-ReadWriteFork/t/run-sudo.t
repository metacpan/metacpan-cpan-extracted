use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

$ENV{PATH} ||= '';
plan skip_all => './.sudo_password is missing' unless -r '.sudo_password';

my $rwf      = Mojo::IOLoop::ReadWriteFork->new;
my $password = Mojo::File->new('.sudo_password')->slurp;
my ($output, $exit_value, $signal) = ('');

chomp $password;

$rwf->on(finish => sub { ($exit_value, $signal) = @_[1, 2]; Mojo::IOLoop->stop });
$rwf->on(
  read => sub {
    $output .= $_[1];
    $rwf->write("$password\n") if $output =~ s!password.*:!!i;
  }
);

$rwf->start(program => 'sudo', program_args => [$^X, -e => q(print "hey $ENV{USER}!\n"; exit 3)], conduit => 'pty');

my @killer = ($rwf);
Scalar::Util::weaken($killer[0]);
Mojo::IOLoop->timer(0.5 => sub { $killer[0]->kill(9) });
Mojo::IOLoop->timer(1   => sub { Mojo::IOLoop->stop; });
Mojo::IOLoop->start;

like $output, qr{hey root}, 'perl -e hey $USER';
is $exit_value, 3, 'exit_value';

done_testing;
