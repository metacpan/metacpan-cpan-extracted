#!perl
use 5.016;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile tempdir);

use lib 'lib';

my $SCRIPT = 'script/syntax-highlight-basic';

#===========================================================================
# CLI Tests
#===========================================================================

#===========================================================================
# --help
#===========================================================================

{
    my $output = `perl -Ilib $SCRIPT --help 2>&1`;
    is($? >> 8, 0, '--help exits 0');
    like($output, qr/Usage:/, '--help prints usage');
}

#===========================================================================
# --version
#===========================================================================

{
    my $output = `perl -Ilib $SCRIPT --version 2>&1`;
    is($? >> 8, 0, '--version exits 0');
    like($output, qr/version/, '--version prints version');
}

#===========================================================================
# stdin input with --language
#===========================================================================

{
    my $output = `echo 'if (\$x) {}' | perl -Ilib $SCRIPT --language perl --format pygments 2>&1`;
    is($? >> 8, 0, 'stdin with --language exits 0');
    like($output, qr/<span class="k">/, 'stdin produces pygments output');
}

#===========================================================================
# File input
#===========================================================================

{
    my ($fh, $filename) = tempfile(SUFFIX => '.pl');
    print $fh 'if ($x) { print "hello"; }';
    close($fh);

    my $output = `perl -Ilib $SCRIPT --format html $filename 2>&1`;
    is($? >> 8, 0, 'file input exits 0');
    like($output, qr/<span style=/, 'file input produces HTML output');
}

#===========================================================================
# Auto-detect language from extension
#===========================================================================

{
    my ($fh, $filename) = tempfile(SUFFIX => '.py');
    print $fh 'def hello(): pass';
    close($fh);

    my $output = `perl -Ilib $SCRIPT --format pygments $filename 2>&1`;
    is($? >> 8, 0, 'auto-detect exits 0');
    like($output, qr/<span class="k">def<\/span>/, 'auto-detected Python keyword highlighted');
}

#===========================================================================
# Unknown file extension (fallback)
#===========================================================================

{
    my ($fh, $filename) = tempfile(SUFFIX => '.xyz');
    print $fh '"hello world"';
    close($fh);

    my $output = `perl -Ilib $SCRIPT --format pygments $filename 2>&1`;
    is($? >> 8, 0, 'unknown extension exits 0 (fallback)');
    like($output, qr/<span class="s">/, 'fallback string detection works');
}

#===========================================================================
# Nonexistent file
#===========================================================================

{
    my $output = `perl -Ilib $SCRIPT /nonexistent/file/path.xyz 2>&1`;
    isnt($? >> 8, 0, 'nonexistent file exits non-zero');
}

#===========================================================================
# --format ansi
#===========================================================================

{
    my $output = `echo 'if (1) {}' | perl -Ilib $SCRIPT --language perl --format ansi 2>&1`;
    is($? >> 8, 0, 'ansi format exits 0');
    my $esc = chr(27);
    like($output, qr/\Q${esc}[0m\E/, 'ansi output contains reset code');
}

#===========================================================================
# --wrap option
#===========================================================================

{
    my $output = `echo 'code' | perl -Ilib $SCRIPT --language perl --format pygments --wrap 2>&1`;
    is($? >> 8, 0, '--wrap exits 0');
    like($output, qr/<div class="highlight">/, '--wrap produces container div');
}

done_testing();