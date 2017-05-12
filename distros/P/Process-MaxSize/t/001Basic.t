######################################################################
# Test suite for Process::MaxSize
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);

use Test::More qw(no_plan);
BEGIN { use_ok('Process::MaxSize') };

# Log::Log4perl->easy_init($DEBUG);

use Process::MaxSize;

my $process_size = Process::MaxSize::process_size();

  # Sanity check
if($process_size < 1000 or
   $process_size > 20000) {
    die "Measured process size $process_size -- please contact the author";
}

my $max_size = $process_size + 1024*5;
my $mega = ("X" x (1024*1024));

my $restarted = 0;
my $p = Process::MaxSize->new(
    restart  => sub { $restarted = 1; },
    max_size => $max_size,
    sleep    => 0,
);

my @arr = ();

$p->check();
is($restarted, 0, "Not yet restarted");

push @arr, $mega;
$p->check();
is($restarted, 0, "Not yet restarted");

for(1..5) {
      # note that we're appending modified strings at the end, 
      # to make sure Perl's COW won't optimize it (this might still
      # break when Perl gets smarter).
    push @arr, $_ . $mega;
    $p->check();
}

is($restarted, 1, "Restarted");
