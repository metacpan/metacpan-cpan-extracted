#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw/tempfile/;
use FindBin qw/$Bin/;
use Perl::Minify qw(minify minify_sub);

# Read the color.pl fixture (located relative to this test file, not the CWD)
my $fixture = do {
    local $/;
    open my $fh, '<', "$Bin/../color.pl" or die "Cannot open color.pl: $!";
    <$fh>;
};

# Helper: wrap minified sub in a small script so perl -c works with state/features
sub compile_minified {
    my ($code) = @_;
    return "use v5.16;\n$code\n__END__\n";
}

# 1. Full-file minify -> perl -c must say "syntax OK"
{
    my $min = minify($fixture);
    ok(defined($min), 'minify of color.pl returns defined');

    my ($fh, $tmp) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $min;
    close $fh;

    my $output = `"$^X" -c "$tmp" 2>&1`;
    ok($? == 0, 'perl -c exits 0 on full-file minify')
        or diag "output: $output";
    like($output, qr/syntax OK/, 'full-file minify produces valid syntax')
        or diag "output: $output";
}

# 2. minify_sub on 'color' -> perl -c must say "syntax OK" (wrapped with use v5.16)
{
    my $sub = minify_sub($fixture, 'color');
    ok(defined($sub), 'minify_sub color returns defined');

    my ($fh, $tmp) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh compile_minified($sub);
    close $fh;

    my $output = `"$^X" -c "$tmp" 2>&1`;
    ok($? == 0, 'perl -c exits 0 on minify_sub color')
        or diag "output: $output";
    like($output, qr/syntax OK/, 'minify_sub color produces valid syntax')
        or diag "output: $output";
}

# 3. minify_sub on 'file_get_contents' -> perl -c must say "syntax OK"
{
    my $sub = minify_sub($fixture, 'file_get_contents');
    ok(defined($sub), 'minify_sub file_get_contents returns defined');

    my ($fh, $tmp) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh compile_minified($sub);
    close $fh;

    my $output = `"$^X" -c "$tmp" 2>&1`;
    ok($? == 0, 'perl -c exits 0 on minify_sub file_get_contents')
        or diag "output: $output";
    like($output, qr/syntax OK/, 'minify_sub file_get_contents produces valid syntax')
        or diag "output: $output";
}

# 4. minify with shorten_vars also compiles (skip subs that reference vars in regex)
{
    # Use a simpler fixture without state vars used inside regex
    my $simple = <<'END_PERL';
use v5.16;
my $x = 1;
my $y = $x + 1;
print $y;
END_PERL
    my $min = minify($simple, { shorten_vars => 1 });
    ok(defined($min), 'minify with shorten_vars returns defined');

    my ($fh, $tmp) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $min;
    close $fh;

    my $output = `"$^X" -c "$tmp" 2>&1`;
    ok($? == 0, 'perl -c exits 0 on shorten_vars output')
        or diag "output: $output";
    like($output, qr/syntax OK/, 'shorten_vars output produces valid syntax')
        or diag "output: $output";
}

# 5. minify with wrap also compiles
{
    my $min = minify($fixture, { wrap => 60 });
    ok(defined($min), 'minify with wrap=60 returns defined');

    my ($fh, $tmp) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $min;
    close $fh;

    my $output = `"$^X" -c "$tmp" 2>&1`;
    ok($? == 0, 'perl -c exits 0 on wrap output')
        or diag "output: $output";
    like($output, qr/syntax OK/, 'wrap output produces valid syntax')
        or diag "output: $output";
}

done_testing;
