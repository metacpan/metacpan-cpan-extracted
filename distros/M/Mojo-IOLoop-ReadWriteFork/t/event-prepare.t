use Mojo::Base -strict;
use Test::More;
use Mojo::IOLoop::ReadWriteFork;

plan skip_all => 'READWRITEFORK_SSH=host is not set' unless $ENV{READWRITEFORK_SSH} or -e '.readwritefork_ssh';

$ENV{READWRITEFORK_SSH} ||= Mojo::File->new('.readwritefork_ssh')->slurp;
chomp $ENV{READWRITEFORK_SSH};

my $columns = int(300 * rand);
my $fork    = Mojo::IOLoop::ReadWriteFork->new;
my (@pipe_names, @pipe_ref);
$fork->on(
  prepare => sub {
    my ($fork, $pipes) = @_;
    @pipe_names = sort keys %$pipes;
    @pipe_ref   = map { ref $pipes->{$_} } sort keys %$pipes;
    $pipes->{stdout_read}->set_winsize(40, $columns);
  }
);

my $output = '';
$fork->on(read => sub { $output .= pop });
$fork->conduit({type => 'pty'})->run_p(ssh => $ENV{READWRITEFORK_SSH}, -t => q(tput cols))->wait;

is_deeply \@pipe_names, [qw(stdin_read stdin_write stdout_read stdout_write)], 'pipe names';
is_deeply \@pipe_ref, ['', 'IO::Pty', 'IO::Pty', ''], 'pipe types';
like $output, qr{$columns\r\n}s, 'changed columns';

done_testing;
