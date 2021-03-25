use Mojo::Base -strict;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

plan skip_all => 'READWRITEFORK_SSH=host is not set' unless $ENV{READWRITEFORK_SSH} or -e '.readwritefork_ssh';

$ENV{READWRITEFORK_SSH} ||= Mojo::File->new('.readwritefork_ssh')->slurp;
chomp $ENV{READWRITEFORK_SSH};

my $fork   = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';
$fork->on(read => sub { $output .= $_[1]; });
$fork->run_p(ssh => $ENV{READWRITEFORK_SSH}, qw( ls -l / ))->wait;

like $output, qr{bin.*sbin}s, 'ls -l';

done_testing;
