use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use NBI::Slurm;
use File::Basename;
# Win32?
if ($^O eq 'MSWin32') {
    plan skip_all => "Skipping all tests: scripts not supported on Windows";
}
# Try executing the scripts in bin to see if at least they run with --version


for my $bin (glob "$RealBin/../bin/*") {
    my $base = basename($bin);
    # Check if they have shebang
    my @lines;
    eval {
        open my $fh, '<', $bin or die "Cannot open $bin: $!";
        @lines = <$fh>;
        close $fh;
        like($lines[0], qr{^#!/}, "$base has shebang");
    };
    if ($@) {
        fail("$base has shebang");
    }
    # Check if #PODNAME: and #ABSTRACT are present
    my $podname = 0;
    my $abstract = 0;
    for my $line (@lines) {
        $podname = 1 if $line =~ /^#PODNAME:/;
        $abstract = 1 if $line =~ /^#ABSTRACT:/;
    }
    ok($podname, "$base has #PODNAME");
    ok($abstract, "$base has #ABSTRACT");

}


done_testing();