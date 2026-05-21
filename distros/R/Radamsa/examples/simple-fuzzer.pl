use 5.010;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

use Radamsa;

my $target = shift @ARGV or die "usage: $0 /path/to/program [sample-file]\n";
my $sample_path = shift @ARGV;

my $sample;
if (defined $sample_path) {
    open my $fh, '<:raw', $sample_path or die "open $sample_path: $!";
    local $/;
    $sample = <$fh>;
    close $fh;
}
else {
    local $/;
    binmode STDIN;
    $sample = <STDIN>;
}

die "sample input is empty\n" unless defined $sample && length $sample;

my $rad = Radamsa->new(seed => 1, max_len => length($sample) * 8);

for my $case (1 .. 100) {
    my $payload = $rad->mutate($sample);

    open my $child, '|-', $target or die "spawn $target: $!";
    binmode $child;
    print {$child} $payload;
    close $child;

    my $exit = $? >> 8;
    my $signal = $? & 127;
    my $core = $? & 128;

    say "case=$case bytes=", length($payload), " exit=$exit signal=$signal core=$core";

    if ($signal || $core) {
        open my $out, '>:raw', "crash-$case.bin" or die "write crash-$case.bin: $!";
        print {$out} $payload;
        close $out;
        die "target crashed on case $case\n";
    }
}
