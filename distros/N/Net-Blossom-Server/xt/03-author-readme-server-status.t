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

for my $route (
    'PUT /upload',
    'HEAD /upload',
    'GET /<sha256>',
    'HEAD /<sha256>',
    'DELETE /<sha256>',
    'GET /list/<pubkey>',
    'PUT /media',
    'HEAD /media',
    'PUT /mirror',
) {
    like($content, qr/\Q$route\E/, "README mentions $route server support");
}

like($content, qr/allowlist-only HTTP mirror fetcher/i,
    'README mentions allowlist HTTP mirror fetcher');

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
