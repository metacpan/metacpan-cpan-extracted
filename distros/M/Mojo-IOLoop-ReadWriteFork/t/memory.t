use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;
use Time::HiRes qw(time);

plan skip_all => 'TEST_MEMORY=10'          unless $ENV{TEST_MEMORY};
plan skip_all => "open /proc/$$/statm: $!" unless do { sysopen my $PROC, "/proc/$$/statm", 0 };

my @tracked, (get_mem_usage());

for (1 .. $ENV{TEST_MEMORY}) {
  my $fork   = Mojo::IOLoop::ReadWriteFork->new;
  my $output = '';
  $fork->on(read => sub { $output .= $_[1] });
  $fork->run_p('dd if=/dev/urandom bs=10M count=1')->wait;

  ok length($output) > 1e6, 'got output';
  sleep 0.2;
  push @tracked, get_mem_usage();
}

ok !Mojo::IOLoop::ReadWriteFork::SIGCHLD->singleton->is_waiting, 'SIGCHLD is idle';

push @tracked, get_mem_usage();
note sprintf "%4s | %8s | %8s | %8s | %8s\n", '', qw(data rss share vsz);
note sprintf "%4s | %8s | %8s | %8s | %8s\n", @$_ for @tracked;

local $TODO = 'Seems to fail if TEST_MEMORY < 10' if $ENV{TEST_MEMORY} < 10;
my %same;
$same{$_->[2]}++ for @tracked;
is int(grep { $_ > $ENV{TEST_MEMORY} / 2 } values %same), 1, 'memory usage stabilizes';

done_testing;

sub get_mem_usage {
  sysopen my $PROC, "/proc/$$/statm", 0 or die $!;
  sysread $PROC, my $proc_info, 255 or die $!;
  my ($vsz, $rss, $share, undef, undef, $data, undef) = split /\s+/, $proc_info, 7;

  # Need to to multipled with page_size_in_kb=4
  state $i = 0;
  return [$i++, map { $_ * 4 } $data, $rss, $share, $vsz];
}
