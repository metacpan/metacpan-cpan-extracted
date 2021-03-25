use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $fork = Mojo::IOLoop::ReadWriteFork->new;
my %events;

# legacy
$fork->on(before_fork => sub { $events{before_fork}++ });
$fork->on(close       => sub { $events{close}++ });
$fork->on(fork        => sub { $events{fork}++ });

# current
$fork->on(error   => sub { $events{error}++ });
$fork->on(finish  => sub { $events{finish}++ });
$fork->on(prepare => sub { $events{prepare}++ });
$fork->on(read    => sub { $events{read}++ });
$fork->on(spawn   => sub { $events{spawn}++ });

$fork->write("line one\nline two\n", sub { shift->close('stdin'); });
$fork->run_p(sub { print while <>; print "FORCE\n"; })->wait;

$events{read} = 1 if $events{read};
is_deeply \%events, {before_fork => 1, close => 1, finish => 1, fork => 1, prepare => 1, read => 1, spawn => 1},
  'got all events';

done_testing;
