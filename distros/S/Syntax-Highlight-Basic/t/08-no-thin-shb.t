#!perl
use 5.016;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename qw(dirname basename);
use File::ShareDir qw(dist_dir);

#===========================================================================
# Regression test: no bundled .shb ships "thin" (no usable rule sections).
#
# Locates the bundled syntax directory the same way Parser.pm does:
# share/syntax relative to the repo in the working tree, falling back to
# File::ShareDir when installed.
#===========================================================================

# Languages intentionally allowed to remain below the soft --min-sections
# threshold (currently 3). This list MUST be empty after Prompt 11's fixes;
# it exists so the soft threshold can be tightened later without spurious
# failures elsewhere.
my %KNOWN_THIN = ();

my $syntax_dir = _find_syntax_dir();

if (!$syntax_dir)
{
    plan skip_all => 'Could not locate bundled share/syntax directory';
}

my @shb_files = sort glob(File::Spec->catfile($syntax_dir, '*.shb'));

if (!@shb_files)
{
    plan skip_all => "No .shb files found in '$syntax_dir'";
}

plan tests => scalar(@shb_files);

for my $file (@shb_files)
{
    my $lang    = basename($file);
    my $sections = _count_sections($file);

    if ($KNOWN_THIN{$lang})
    {
        ok(1, "$lang: below soft threshold but allow-listed in \%KNOWN_THIN");
    }
    else
    {
        ok($sections >= 1, "$lang has at least 1 rule section (found $sections)");
    }
}

done_testing();

#===========================================================================
# Count [keyword:...]/[match:...]/[region:...] section headers in a .shb
# file, ignoring comments, blank lines, and header lines.
#===========================================================================

sub _count_sections
{
    my ($file) = @_;

    my $count = 0;
    my $fh;

    open($fh, '<', $file) or return 0;
    while (my $line = <$fh>)
    {
        next if $line =~ /^\s*#/;
        next if $line =~ /^\s*$/;
        if ($line =~ /^\[(?:keyword|match|region):/)
        {
            $count++;
        }
    }
    close $fh;

    return $count;
}

#===========================================================================
# Locate the bundled syntax directory: prefer the working-tree share/syntax
# (repo checkout), falling back to File::ShareDir when installed.
#===========================================================================

sub _find_syntax_dir
{
    my $here = dirname(File::Spec->rel2abs(__FILE__));
    my $repo_dir = File::Spec->catdir($here, File::Spec->updir, 'share', 'syntax');

    if (-d $repo_dir && glob(File::Spec->catfile($repo_dir, '*.shb')))
    {
        return $repo_dir;
    }

    my $found;
    eval {
        my $share_dir = dist_dir('Syntax-Highlight-Basic');
        my $dir       = File::Spec->catdir($share_dir, 'syntax');
        $found = $dir if -d $dir;
    };

    return $found;
}
