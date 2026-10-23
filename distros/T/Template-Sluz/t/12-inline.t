use strict;
use warnings;
use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

use File::Temp qw(tempfile);

my $MARKER = '__DATA__';

my $sluz = setup_sluz();

# Build a throwaway "script" file whose data section holds $body. $prefix is
# source placed above the marker (may mention the marker in comments/strings).
# Returns a Template::Sluz instance pointed at that file.
sub inline_instance {
    my ($prefix, $body) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    binmode $fh;
    print $fh "${prefix}$MARKER\n$body";
    close $fh;

    my $s = Template::Sluz->new();
    $s->assign(name => 'N', y => [1, 2], debug => 1);
    $s->{perl_file} = $path;
    return $s;
}

# -------------------------------------------------------------------
# Inline data-section content via fetch()
# -------------------------------------------------------------------
my $out = $sluz->fetch();
like($out, qr/Hello inline Scott Baker!/, 'Inline #1 - fetch() renders its own data section');

my $f = $sluz->{perl_file};
ok($f, 'Inline #2 - perl_file resolved');

my $line_no = 1;
{
    open my $fh2, '<', $f or die "Cannot open $f: $!";
    while (<$fh2>) {
        last if /^\Q$MARKER\E\s*$/;
        $line_no++;
    }
    close $fh2;
}
is($sluz->{tpl_line_offset}, $line_no, 'Inline #3 - line offset matches marker line number');

# -------------------------------------------------------------------
# Direct _get_inline_content unit tests
# -------------------------------------------------------------------
my ($fh, $path);

# LF file
($fh, $path) = tempfile();
binmode $fh;
print $fh "#!/usr/bin/perl\nmy \@x = 1;\n$MARKER\nline one\nline two\n";
close $fh;
my ($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, "line one\nline two\n", 'LF #1 - content extracted');
is($line_offset, 3, 'LF #2 - line offset counts marker line');

# CRLF file
($fh, $path) = tempfile();
binmode $fh;
print $fh "#!/usr/bin/perl\nmy \@x = 1;\n$MARKER\r\nline one\r\nline two\r\n";
close $fh;
($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, "line one\r\nline two\r\n", 'CRLF #1 - content starts clean (no stray newline)');
is($line_offset, 3, 'CRLF #2 - line offset counts marker line');

# Marker at EOF with no trailing newline
($fh, $path) = tempfile();
binmode $fh;
print $fh "a\n${MARKER}tail only";
close $fh;
($content, $line_offset) = $sluz->_get_inline_content($path);
is($content, '', 'EOF #1 - no newline after marker, empty content');
is($line_offset, 1, 'EOF #2 - offset counts newlines before data (none after marker)');

# No marker section
($fh, $path) = tempfile();
binmode $fh;
print $fh "no data section here\n";
close $fh;
is($sluz->_get_inline_content($path), undef, 'NoData #1 - no marker returns undef');
ok(!exists $sluz->{_inline_cache}{$path}, 'NoData #2 - undef not cached');

# -------------------------------------------------------------------
# Cache behavior
# -------------------------------------------------------------------
ok(exists $sluz->{_inline_cache}{$f}, 'Cache #1 - inline content cached by file');

my ($c1, $o1) = $sluz->_get_inline_content($f);
my ($c2, $o2) = $sluz->_get_inline_content($f);
is($c1, $c2, 'Cache #2 - repeated calls return same content');
is($o1, $o2, 'Cache #3 - repeated calls return same offset');
is($sluz->fetch(), $out, 'Cache #4 - repeated fetch() renders identical output');

# -------------------------------------------------------------------
# Marker detection: only a line consisting of the marker counts. A mention
# inside a comment or string above the real marker must be ignored.
# -------------------------------------------------------------------
{
    my $s = inline_instance("# $MARKER is mentioned here\nmy \$x = '$MARKER';\n", "real {\$name}\n");
    is($s->fetch(), "real N\n", 'Inline #9 - Marker text in a comment or string is ignored');
}

# -------------------------------------------------------------------
# Section content: custom delimiters, blocks, and errors
# -------------------------------------------------------------------
{
    my $s = inline_instance('', 'ALT [$name] {$name}');
    $s->set_delimiters('[', ']');
    is($s->fetch(), 'ALT N {$name}', 'Inline #15 - Custom delimiters apply to the inline section');
}

{
    my $s = inline_instance('', '{foreach $y as $v}[{$v}]{/foreach}{if $debug}ON{/if}');
    is($s->fetch(), '[1][2]ON', 'Inline #16 - foreach and if blocks render in the inline section');
}

{
    my $s = inline_instance('', '{$name|nonexistent_xyz}');
    eval { $s->fetch() };
    like($@, qr/#47204/, 'Inline #17 - Modifier error inside the inline section is reported');
}

# -------------------------------------------------------------------
# Error line numbers in the inline section report the line in the source file.
# Marker is on file line 2, so section line 4 ("{foo") is file line 6.
# -------------------------------------------------------------------
{
    my $s = inline_instance("use strict;\n", "\nline one\nline two\n{foo\n");
    eval { $s->fetch() };
    like($@, qr/on line #6\b/, 'Inline #18 - Inline error reports its line in the source file');
}

done_testing();

__DATA__
Hello inline {$first} {$last}!
