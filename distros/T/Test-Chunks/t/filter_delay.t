# Each filter should have access to chunks/chunk internals.
use Test::Chunks;

filters qw(chomp lower);
filters_delay;

plan tests => 8 * chunks;

for my $chunk (chunks) {
    ok(not($chunk->is_filtered));
    unlike($chunk->section, qr/[a-z]/);
    like($chunk->section, qr/^I L/);
    like($chunk->section, qr/\n/);
    $chunk->run_filters;
    ok($chunk->is_filtered);
    like($chunk->section, qr/[a-z]/);
    like($chunk->section, qr/^i l/);
    unlike($chunk->section, qr/\n/);
}

sub lower {
    lc(shift);
}

__DATA__
=== One
--- section
I LIKE IKE

=== One
--- section
I LOVE LUCY
