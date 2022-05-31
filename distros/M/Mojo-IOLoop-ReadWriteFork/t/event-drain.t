use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

BEGIN {
  eval 'use Test::Memory::Cycle;1' or Mojo::Util::monkey_patch(main => memory_cycle_ok => sub { });
}

my $rwf    = Mojo::IOLoop::ReadWriteFork->new;
my $drain  = 0;
my $output = '';

$rwf->on(close => sub { Mojo::IOLoop->stop; });
$rwf->on(read  => sub { $output .= $_[1]; });
$rwf->write("line one\n", sub { $drain++; });
$rwf->start(
  program => sub {
    print sysread STDIN, my $buf, 1024;
    print "\n$buf";
    print "line two\n";
  }
);

Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
memory_cycle_ok $rwf, 'no cycle after run';

like $output, qr/^9\nline one\nline two\n/, 'can write() before start()' or diag $output;
is $drain, 1, 'drain callback was called';

done_testing;
