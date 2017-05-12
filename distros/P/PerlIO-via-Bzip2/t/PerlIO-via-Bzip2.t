# Tests for PerlIO::via::Bzip2

use blib;

use strict;
use warnings;

use Test::More tests => 41;

use File::Copy;

BEGIN {
    chdir('t') if -d 't';
    use_ok('PerlIO::via::Bzip2');
};

# Check defaults
cmp_ok(PerlIO::via::Bzip2->level, '==', 1, "default worklevel");

my $fh;

# Opening/closing
ok(open($fh, "<:via(Bzip2)", "ipsum_small.bz2"), "open for reading");
ok(close($fh), "close file");

ok(!open($fh, "+<:via(Bzip2)", "ipsum_small.bz2"),
   "cannot read/write a bzip2 file ('+<')");

ok(open($fh, ">:via(Bzip2)", "out.bz2"), "open for write");
ok(close($fh), "close file");

ok(!open($fh, "+>:via(Bzip2)", "out.bz2"),
    "cannot read/write a bzip2 file ('+>')");

ok(!open($fh, ">>:via(Bzip2)", "out.bz2"),
   "cannot open a bzip2 file for appen ('>>')");

# Decompression
for my $size (qw/small large/) {
    open($fh, "<:via(Bzip2)", "ipsum_$size.bz2");
    open(my $fh_orig, "<", "ipsum_$size.txt");
    {
        local $/ = undef;
        my $orig = <$fh_orig>;
        my $decompressed = <$fh>;
        is($decompressed, $orig, "$size file decompression");
    }
}

# Compression
for my $size (qw/small large/) {
    # The original text file
    ok(open(my $fh_orig,     "<", "ipsum_$size.txt"),
       "open $size uncompressed file for reading");
    # The original text file, compressed
    ok(open(my $fh_orig_cmp, "<", "ipsum_$size.bz2"),
       "open $size compressed original for reading");
    # Create a new, bzipped file
    ok(open($fh, ">:via(Bzip2)", "ipsum_${size}_via.bz2"),
       "open $size file to compress to");
    {
        # Get original and write it (via Bzip2 layer) to the compressed
        # file.
        local $/ = undef;
        my $orig = <$fh_orig>;
        ok((print {$fh} $orig), "write and compress");
        ok(close($fh), "close file");

        # Get the created file and the original, compare.
        ok(open($fh, "<", "ipsum_${size}_via.bz2"),
           "open the created $size file");
        my $cmp_via = <$fh>;
        my $cmp_orig = <$fh_orig_cmp>;
        ok($cmp_via eq $cmp_orig, "$size file compression");
    }
}

# Use the default settings to create a file and check the header for the 
# buffer size.
ok(open($fh, ">:via(Bzip2)", "out.bz2"), "open for write");
ok((print {$fh} "foo"), "compression");
ok(close($fh), "close file");
ok(open(my $in_fh, "<", "out.bz2"), "open for read (uncompressed)");
{
    local $/ = undef;
    my $cmp = <$in_fh>;
    is(substr($cmp, 3, 1), "1", "blocksize 100k");
}
ok(close($in_fh), "close file");

PerlIO::via::Bzip2->level(9);
cmp_ok(PerlIO::via::Bzip2->level, '==', 9, "set worklevel");

ok(open($fh, ">:via(Bzip2)", "out.bz2"), "open for write");
ok((print {$fh} "foo"), "compression");
ok(close($fh), "close file");
ok(open($in_fh, "<", "out.bz2"), "open for read (uncompressed)");
{
    local $/ = undef;
    my $cmp = <$in_fh>;
    is(substr($cmp, 3, 1), "9", "blocksize 900k");
}
ok(close($in_fh), "close file");

END {
    for my $file (qw/out.bz2 ipsum_small_via.bz2 ipsum_large_via.bz2/) {
        ok(unlink $file, "remove $file intermediate file");
    }
}
