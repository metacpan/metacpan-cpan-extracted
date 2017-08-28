use Mojo::Base -strict;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

plan skip_all => 'READWRITEFORK_SSH=host is not set' unless $ENV{READWRITEFORK_SSH} or -e '.readwritefork_ssh';

$ENV{READWRITEFORK_SSH} ||= Mojo::File->new('.readwritefork_ssh')->slurp;
chomp $ENV{READWRITEFORK_SSH};

my $fork = Mojo::IOLoop::ReadWriteFork->new;
my ($read, $exit_value);

$fork->on(read => sub { $read .= $_[1]; });
$fork->on(close => sub { $exit_value = $_[1]; Mojo::IOLoop->stop; });
$fork->run(ssh => $ENV{READWRITEFORK_SSH}, qw( ls -l / ));
Mojo::IOLoop->start;

like $read, qr{bin.*sbin}s, 'ls -l';
is $exit_value, 0, 'exit_value';

done_testing;
