#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();
use FindBin;

# The code is XS. A .pm holds its package line, use lines, $VERSION, the XS
# bootstrap and POD, and nothing else.
my @ALLOWED = (
    qr/^package [\w:]+;$/,
    qr/^use [\w:.]+(?: (?:\(\)|'[^']*'|qw\([^)]*\)))?;$/,
    qr/^our \$VERSION = '[\d._]+';$/,
    qr/^require XSLoader;$/,
    qr/^XSLoader::load\('[\w:]+', \$VERSION\);$/,
    qr/^1;$/,
);

my @pm;
File::Find::find(sub { push @pm, $File::Find::name if /\.pm\z/ }, "$FindBin::Bin/../lib");
ok(@pm >= 3, 'found the modules');

for my $file (sort @pm) {
    open my $fh, '<', $file or die "$file: $!";
    my ($pod, @bad) = (0);
    while (my $line = <$fh>) {
        chomp $line;
        last if $line eq '__END__';
        if ($line =~ /^=(\w+)/) { $pod = $1 ne 'cut'; next }
        next if $pod || $line =~ /^\s*$/;
        push @bad, "$.: $line" unless grep { $line =~ $_ } @ALLOWED;
    }
    (my $short = $file) =~ s{.*/lib/}{lib/};
    ok(!@bad, "$short has no code") or diag join "\n", @bad;
}

done_testing;
