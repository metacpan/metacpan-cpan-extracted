use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $rwf = Mojo::IOLoop::ReadWriteFork->new;
my %events;

# legacy
$rwf->on(before_fork => sub { $events{before_fork}++ });
$rwf->on(close       => sub { $events{close}++ });
$rwf->on(fork        => sub { $events{fork}++ });

# current
$rwf->on(error   => sub { $events{error}++ });
$rwf->on(finish  => sub { $events{finish}++ });
$rwf->on(prepare => sub { $events{prepare}++ });
$rwf->on(read    => sub { $events{read}++ });
$rwf->on(spawn   => sub { $events{spawn}++ });

$rwf->write("line one\nline two\n", sub { shift->close('stdin'); });
$rwf->run_p(sub { print while <>; print "FORCE\n"; })->wait;

$events{read} = 1 if $events{read};
is_deeply \%events, {before_fork => 1, close => 1, finish => 1, fork => 1, prepare => 1, read => 1, spawn => 1},
  'got all events';

done_testing;
