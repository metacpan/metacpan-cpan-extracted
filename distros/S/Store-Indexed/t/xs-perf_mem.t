use strict;
use warnings;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);
use Store::Indexed::XS;

sub rss_kb {
    open my $fh, "<", "/proc/$$/status" or return 0;
    while (<$fh>) {
        return $1 if /^VmRSS:\s+(\d+)\s+kB/;
    }
    return 0;
}

my $iterations = 100_0000;

my $start = [gettimeofday];

my $store = Store::Indexed::XS->new("val");

my $mem_init = rss_kb();

warn "RSS after setup: " . ((rss_kb -$mem_init));
for my $i (1 .. $iterations) {
    $store->set_val($i, "data-$i");
}
my $elapsed_insert = tv_interval($start);
diag(   "Performance after insert: Inserted $iterations items in "
      . sprintf("%.4f", $elapsed_insert)
      . "s");
warn "RSS after insert: " . (rss_kb -$mem_init);


my $start_get = [gettimeofday];
for my $i (1 .. $iterations) {
    my $val = $store->get_val($i);
    die "Mismatch at $i" unless $val eq "data-$i";
}
my $elapsed_get = tv_interval($start_get);
diag(   "Performance: Retrieved $iterations items in "
      . sprintf("%.4f", $elapsed_get)
      . "s");
warn "RSS after retrieve: " . (rss_kb -$mem_init);

undef $store;
warn "RSS after release: " . (rss_kb -$mem_init);

pass("Completed $iterations insertions and retrievals without crash");

done_testing();
