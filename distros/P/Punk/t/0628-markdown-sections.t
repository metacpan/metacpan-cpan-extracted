#!perl

# A section of the markdown mount's sidebar (a top-level directory) takes its
# label and its place from its index page: `section:` and `section_order:` in
# guide/index.md. A section that says nothing is labelled from its directory
# name and sorts by that name, after every section given a place, as before.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
}

sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? ($r->[2][0] // '') : undef }

sub spew {
    my ($file, $text) = @_;
    (my $dir = $file) =~ s{/[^/]+\z}{};
    mkdir $dir unless -d $dir;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} $text;
    close $fh;
}

my $n = 0;
sub build {
    my ($tree) = @_;
    my $pkg = 'MDSections' . ++$n;
    eval "package $pkg; use Punk; 1" or die $@;
    $pkg->punk_app->markdown('/d' => "$tree", search => 0, sort => 'order');
    return $pkg->to_app;
}

sub nav {
    my ($app, $path) = @_;
    my ($nav) = body(hit($app, path => $path // '/d')) =~ m{(<ul class="punk-md-nav">.*?</ul>\s*</nav>)}s;
    return $nav // '';
}

{
    my $tree = File::Temp->newdir;
    spew("$tree/index.md",        "# Home\n");
    spew("$tree/alpha/one.md",    "# Alpha One\n");
    spew("$tree/delta/one.md",    "# Delta One\n");
    spew("$tree/beta/index.md",   "---\ntitle: Beta Main\nsection: The Beta Library\nsection_order: 2\n---\n# Beta\n");
    spew("$tree/beta/sub.md",     "---\norder: 1\n---\n# Beta Sub\n");
    spew("$tree/gamma/index.md",  "---\nsection_order: 1\n---\n# Gamma Main\n");
    spew("$tree/gamma/other.md",  "# Gamma Other\n");

    my $nav = nav(build($tree));
    my @labels = $nav =~ m{<summary>(.*?)</summary>}g;
    is_deeply \@labels, ['Gamma', 'The Beta Library', 'Alpha', 'Delta'],
        'placed sections first by section_order, then the rest by name; section: labels, else the directory';

    my @links = $nav =~ m{<a href="/d([^"]*)"}g;
    is_deeply \@links, ['', '/gamma', '/gamma/other', '/beta', '/beta/sub', '/alpha/one', '/delta/one'],
        'the root page first, then each section with its index leading';

    like $nav, qr{<a href="/d/beta">Beta Main</a>}, "the index page keeps its own label inside the section";
}

{
    # Nothing said: exactly the old behaviour, sections by directory name.
    my $tree = File::Temp->newdir;
    spew("$tree/index.md",          "# Home\n");
    spew("$tree/recipes/a.md",      "# A recipe\n");
    spew("$tree/guide/index.md",    "# Guide\n");
    spew("$tree/guide/intro.md",    "---\norder: 1\n---\n# Intro\n");
    my $nav = nav(build($tree));
    is_deeply [ $nav =~ m{<summary>(.*?)</summary>}g ], ['Guide', 'Recipes'],
        'with no section keys the sections are named and ordered by their directories';
}

{
    # section: on a page that is not its section's index is ignored.
    my $tree = File::Temp->newdir;
    spew("$tree/guide/intro.md", "---\nsection: Not This\nsection_order: 0\n---\n# Intro\n");
    spew("$tree/zeta/z.md",      "# Z\n");
    my $nav = nav(build($tree), '/d/guide/intro');
    is_deeply [ $nav =~ m{<summary>(.*?)</summary>}g ], ['Guide', 'Zeta'],
        'only a section index names or places its section';
}

done_testing();
