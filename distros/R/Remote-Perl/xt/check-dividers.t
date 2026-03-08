use v5.36;
use Test::More;
use File::Find;

# Check that all padding-style divider comments are exactly 80 characters wide.
#
# Dividers match /^\s*# --.*-{4,}$/ or /^\s*# ==.*={4,}$/ -- the trailing
# 4+ characters distinguish real padding dividers from short section markers
# like "# --- foo ---" used in some test files.

my @files;
find(sub {
    return unless -f;
    push @files, $File::Find::name
        if /\.(?:pm|pl|t)$/ || $_ eq 'remperl';
}, qw(lib bin t xt examples));

for my $file (sort @files) {
    open my $fh, '<', $file or die "open $file: $!\n";
    my $lnum = 0;
    while (my $line = <$fh>) {
        $lnum++;
        chomp $line;
        next unless $line =~ /^\s*# --.*-{4,}$/ || $line =~ /^\s*# ==.*={4,}$/;
        my $label = "$file:$lnum";
        $label .= " ('$1')" if $line =~ /^\s*# [-=]+\s+(.*?)\s*[-=]{4,}$/;
        is(length($line), 80, "$label: divider is 80 chars");
    }
}

done_testing;
