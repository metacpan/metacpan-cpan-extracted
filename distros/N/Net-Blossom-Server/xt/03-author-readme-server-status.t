use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $root = _repo_root();
my $readme = "$root/README.md";

open my $fh, '<', $readme
    or die "Unable to read $readme: $!";
my $content = do { local $/; <$fh> };

unlike($content, qr/server behavior is still scaffold-only/i,
    'README does not describe implemented server behavior as scaffold-only');

for my $dist (
    '`dist/Net-Blossom`: shared protocol objects and the client library.',
    '`dist/Net-Blossom-Server`: server-side support and storage backend contracts.',
    '`dist/Net-Blossom-Server-Backend-SQLite`: SQLite storage backend.',
    '`dist/Net-Blossom-Server-Backend-Postgres`: Postgres storage backend.',
) {
    like($content, qr/\Q$dist\E/, "README mentions $dist");
}

done_testing;

sub _repo_root {
    my $dir = $FindBin::Bin;
    while (1) {
        return $dir if -d "$dir/.git";

        my $parent = "$dir/..";
        last if $parent eq $dir;
        $dir = $parent;
    }

    die "Unable to find repository root from $FindBin::Bin";
}
