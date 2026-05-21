use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More tests => 3;

use_ok('Parallel::Scoreboard');

my $base_dir = tempdir(CLEANUP => 1);

my $sb = Parallel::Scoreboard->new(
    base_dir => $base_dir,
);

# simulate a .tmp file left by another worker (id != $$)
my $tmp_path = "$base_dir/status_99999.tmp";
open my $tmp_fh, '>', $tmp_path or die "failed to create tmp fixture: $!";

$sb->update('me manager');

my $stats = $sb->read_all();

ok(-e $tmp_path, 'read_all does not unlink .tmp files');
is_deeply($stats, {$$ => 'me manager'}, 'read_all only returns real status files');
