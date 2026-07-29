#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use IO::String;
use File::Temp qw(tempfile);
use File::Spec;

BEGIN {
    use_ok('PDF::Reuse') or BAIL_OUT "Can't load PDF::Reuse";
}

# RT #130152 / GitHub #12
# sprintf with undefined objekt values should not warn
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    prFile($tmpfile);
    prText(100, 700, 'Test RT 130152');
    prEnd();

    my @undef_warnings = grep { /uninitialized value/ } @warnings;
    is(scalar @undef_warnings, 0,
        'RT #130152: No uninitialized value warnings from sprintf');
}

# RT #171691 / GitHub #13
# IO::String untie: writing to IO::String then calling prFile() again
# should not produce "Can't locate object method OPEN" error
{
    my $pdf_data = '';
    my $io = IO::String->new($pdf_data);

    my $ok = eval {
        prFile($io);
        prText(100, 700, 'IO::String test');
        prEnd();

        # This second prFile call would fail without the untie fix
        my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
        close $fh;
        prFile($tmpfile);
        prText(100, 700, 'After IO::String');
        prEnd();
        1;
    };
    my $err = $@;

    ok($ok, 'RT #171691: prFile() works after IO::String write')
        or diag("Error: $err");

    ok(length($pdf_data) > 0,
        'RT #171691: IO::String received PDF data');
}

# RT #120459 / GitHub #19
# defined(%hash) - module loads and prDocForm compiles without error
# (This was a compile-time failure on Perl 5.24+)
{
    my $ok = eval {
        # Force loading of the prDocForm code path
        # (previously hidden behind AutoLoader)
        my $exists = defined &PDF::Reuse::prDocForm;
        1;
    };
    ok($ok, 'RT #120459: prDocForm compiles without defined(%hash) error');
}

# GitHub #8
# prDocForm should not crash with "undefined value as ARRAY reference"
# when %links has entries but not for the current page
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    # Generate a simple PDF, then try to use it with prDocForm
    prFile($tmpfile);
    prText(100, 700, 'Source PDF for prDocForm test');
    prEnd();

    my ($fh2, $outfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh2;

    my $ok = eval {
        prFile($outfile);
        prDocForm($tmpfile);
        prEnd();
        1;
    };
    my $err = $@;

    ok($ok, 'GitHub #8: prDocForm does not crash on undefined links')
        or diag("Error: $err");
}

# RT #83185 / GitHub #20
# crossrefObj should not warn about non-numeric arguments
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    prFile($tmpfile);
    prText(100, 700, 'Test RT 83185');
    prEnd();

    my @numeric_warnings = grep { /isn't numeric/ } @warnings;
    is(scalar @numeric_warnings, 0,
        "RT #83185: No 'isn't numeric' warnings from crossrefObj");
}

# RT #168975 / GitHub #11
# prForm() should accept IO::String objects as file input
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    # First, generate a source PDF
    my ($sfh, $srcfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $sfh;
    prFile($srcfile);
    prText(100, 700, 'Source for prForm IO::String test');
    prEnd();

    # Read it into an IO::String
    open(my $in, '<', $srcfile) or die "Can't open $srcfile: $!";
    binmode $in;
    my $pdf_data = do { local $/; <$in> };
    close $in;
    my $io = IO::String->new($pdf_data);

    # Use the IO::String as input to prForm
    my $ok = eval {
        prFile($tmpfile);
        prForm({ file => $io });
        prEnd();
        1;
    };
    my $err = $@;

    ok($ok, 'RT #168975: prForm() accepts IO::String input')
        or diag("Error: $err");
    ok(-s $tmpfile > 0, 'RT #168975: Output PDF has content');
}

# GitHub #24
# prTTFont leaves orphaned $docProxy causing prEnd() crash.
# The DESTROY method on the TTFont wrapper was calling release() on the
# TTFont0 object (wiping its uid), while the DocProxy still held a reference.
SKIP: {
    eval { require Text::PDF::TTFont0; require Font::TTF::Font; };
    skip 'Text::PDF::TTFont0 or Font::TTF not available', 3 if $@;

    my @fonts = glob('/usr/share/fonts/truetype/*/*.ttf');
    skip 'No TTF fonts found on system', 3 unless @fonts;
    my $font = $fonts[0];

    # Test 1: Normal prTTFont session works
    my ($fh1, $file1) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh1;
    my $ok1 = eval {
        prFile($file1);
        prPage();
        prTTFont($font);
        prEnd();
        1;
    };
    ok($ok1, 'GitHub #24: prTTFont in normal session does not crash')
        or diag("Error: $@");

    # Test 2: prInitVars clears docProxy
    my ($fh2, $file2) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh2;
    prFile($file2);
    prPage();
    prTTFont($font);
    prInitVars();
    {
        no strict 'refs';
        is(${"PDF::Reuse::docProxy"}, undef,
            'GitHub #24: prInitVars clears docProxy');
    }

    # Test 3: Multiple sessions with prTTFont do not crash
    my ($fh3, $file3) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh3;
    my ($fh4, $file4) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh4;
    my $ok3 = eval {
        prFile($file3);
        prPage();
        prTTFont($font);
        prEnd();
        prFile($file4);
        prPage();
        prTTFont($font);
        prEnd();
        1;
    };
    ok($ok3, 'GitHub #24: Multiple prTTFont sessions do not crash')
        or diag("Error: $@");
}

# GitHub #21 / #22 (RT #103758, RT #103768)
# %processed caches byte offsets keyed by filename. Reusing a filename for
# fresh content within one session must not apply the old file's offsets to
# the new bytes -- that failed with "Didn't find pages" on the second pass.
{
    my $dir = File::Temp->newdir();
    my $tpl = File::Spec->catfile($dir, 'tpl.pdf');

    my $build = sub {
        my ($pages, $label) = @_;
        prFile($tpl);
        for my $p (1 .. $pages) {
            prPage() if $p > 1;
            prFontSize(24);
            prText(72, 700, "$label page $p");
        }
        prEnd();
    };

    my $ok = eval {
        for my $i (1 .. 3) {
            $build->($i * 3, "ITER$i");
            prFile(File::Spec->catfile($dir, "out_$i.pdf"));
            prDoc($tpl);
            prEnd();
        }
        1;
    };
    ok($ok, 'GitHub #21/#22: reusing a filename for new content does not die')
        or diag("Error: $@");

    # The cache must survive for a file that has NOT changed -- that is what it
    # exists for, and clearing it wholesale would be a performance regression.
    my $fixed = File::Spec->catfile($dir, 'fixed.pdf');
    prFile($fixed);
    prPage();
    prText(72, 700, 'unchanged template');
    prEnd();

    prFile(File::Spec->catfile($dir, 'r1.pdf'));
    prDoc($fixed);
    prEnd();
    my $first = do { no strict 'refs'; ${"PDF::Reuse::processed"}{$fixed}{root} };

    prFile(File::Spec->catfile($dir, 'r2.pdf'));
    prDoc($fixed);
    prEnd();
    my $second = do { no strict 'refs'; ${"PDF::Reuse::processed"}{$fixed}{root} };

    ok(defined $first && defined $second,
        'GitHub #21/#22: cache retained across reuse of an unchanged file');
    is($second, $first,
        'GitHub #21/#22: cached root is stable for an unchanged file');
}

# RT #123564 / GitHub #15
# Embedded TrueType text must be extractable, which requires a /ToUnicode CMap.
# Text::PDF::TTFont0's own ToUnicode support emits a malformed CMap (RT #123562,
# unfixed upstream), so PDF::Reuse builds the mapping itself.
SKIP: {
    # Runners differ: Linux images carry DejaVu/Liberation, macOS keeps fonts
    # under /System or /Library, Windows under the system root. Glob rather
    # than list, so this exercises the CMap on every platform that has any
    # TrueType font rather than silently skipping.
    my @globs = (
        '/usr/share/fonts/truetype/*/*.ttf',
        '/usr/share/fonts/*/*.ttf',
        '/Library/Fonts/*.ttf',
        '/System/Library/Fonts/*.ttf',
        '/System/Library/Fonts/Supplemental/*.ttf',
        ($ENV{SystemRoot} ? "$ENV{SystemRoot}\\Fonts\\*.ttf" : ()),
        'C:/Windows/Fonts/*.ttf',
    );
    my ($ttf) = grep { -r $_ } map { glob $_ } @globs;
    skip 'no TrueType font available on this platform', 4 unless $ttf;
    diag("using font: $ttf");

    my $dir = File::Temp->newdir();
    my $out = File::Spec->catfile($dir, 'tt.pdf');

    prInitVars();
    prFile($out);
    prTTFont($ttf);
    prFontSize(14);
    prText(60, 700, 'Hello ToUnicode');
    prEnd();

    open my $fh, '<', $out or BAIL_OUT "can't read $out: $!";
    binmode $fh;
    my $pdf = do { local $/; <$fh> };
    close $fh;

    like($pdf, qr{/ToUnicode}, 'GitHub #15: /ToUnicode key present for TrueType font');
    like($pdf, qr{beginbfchar}, 'GitHub #15: CMap uses bfchar mappings');
    like($pdf, qr{currentdict}, 'GitHub #15: CMap trailer is well formed');

    # Every section must declare exactly as many entries as it contains --
    # a miscount produces a CMap some readers silently reject.
    my @declared = $pdf =~ /(\d+) beginbfchar/g;
    my @bodies   = $pdf =~ /beginbfchar\n(.*?)endbfchar/gs;
    my $consistent = scalar(@declared) == scalar(@bodies);
    if ($consistent) {
        for my $i (0 .. $#declared) {
            my $actual = grep { /\S/ } split /\n/, $bodies[$i];
            $consistent = 0 if $actual != $declared[$i];
        }
    }
    ok($consistent, 'GitHub #15: each bfchar section declares its true entry count');
}
