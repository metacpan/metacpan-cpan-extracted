#!perl

# `date:` and `updated:` in front matter, and `sort => 'date'`: newest first,
# ties by title then path, undated pages last. A date that does not parse is a
# configuration error and fails at boot naming the file.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();
use Time::Local ();
use Config ();

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
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} $text;
    close $fh;
}

sub nav_order {
    my $b = shift;
    my ($nav) = $b =~ m{<ul class="punk-md-nav">(.*?)</ul>\s*</nav>}s;
    return [ ($nav // '') =~ m{<a href="([^"]+)"}g ];
}

my $n = 0;
sub mount {
    my (%o) = @_;
    my $pkg = 'MDDate' . ++$n;
    my $dir = delete $o{dir};
    my @opt = %o;
    eval "package $pkg; use Punk; markdown '/b' => \$dir, search => 0, \@opt; 1"
        or die $@;
    return $pkg->to_app;
}

my $tmpl = File::Temp->newdir;
spew("$tmpl/wrapper.tmpl", "{% content %}");
spew("$tmpl/app.css", "");
spew("$tmpl/page.tmpl", join "\n",
     'DATE=[{% date %}]', 'ISO=[{% date_iso %}]', 'HUMAN=[{% date_human %}]',
     'UPD=[{% updated %}]', 'UPDISO=[{% updated_iso %}]', '');

# ---- the order ---------------------------------------------------------------

my $tree = File::Temp->newdir;
spew("$tree/oldest.md",  "---\ndate: 2026-10-01\n---\n# Oldest\n");
spew("$tree/one.md",     "---\ndate: 2026-10-19\n---\n# Beta\n");
spew("$tree/two.md",     "---\ndate: 2026-10-19\n---\n# Alpha\n");
spew("$tree/offset.md",  "---\ndate: 2026-10-19T01:00:00+02:00\n---\n# Offset\n");
spew("$tree/newest.md",  "---\ndate: 2026-10-20T08:30Z\n---\n# Newest\n");
spew("$tree/zeta.md",    "# Zeta undated\n");
spew("$tree/aaa.md",     "# Aaa undated\n");
mkdir "$tree/nested";
spew("$tree/nested/deep.md", "---\ndate: 2026-10-10\n---\n# Deep\n");

{
    my $app = mount(dir => "$tree", sort => 'date');
    is_deeply nav_order(body(hit($app, path => '/b/one'))),
        [ map "/b/$_", qw(newest two one offset nested/deep oldest aaa zeta) ],
        'date: newest first, a tie by title (not path), an offset read as UTC, '
      . 'sections ignored, undated last in path order';

    my $r = hit($app, path => '/b');
    is $r->[0], 301, 'with no index, the mount root redirects';
    my %h = @{ $r->[1] };
    is $h{Location}, '/b/newest', '...to the newest page';
}

{
    my $app = mount(dir => "$tree");
    my $o = nav_order(body(hit($app, path => '/b/one')));
    isnt $o->[0], '/b/newest', 'the default sort is unchanged by dates';
}

# ---- the fields --------------------------------------------------------------

{
    my $app = mount(dir => "$tree", sort => 'date', template_dir => "$tmpl");
    my $b = body(hit($app, path => '/b/newest'));
    my $t = Time::Local::timegm(0, 30, 8, 20, 9, 2026);
    like $b, qr{DATE=\[$t\]}, 'date is the epoch';
    like $b, qr{ISO=\[2026-10-20T08:30:00Z\]}, 'date_iso';
    like $b, qr{HUMAN=\[20 October 2026\]}, 'date_human';
    like $b, qr{UPD=\[$t\]}, 'updated defaults to the date';
    like $b, qr{UPDISO=\[2026-10-20T08:30:00Z\]}, '...and so does updated_iso';

    $b = body(hit($app, path => '/b/offset'));
    like $b, qr{ISO=\[2026-10-18T23:00:00Z\]}, 'an offset is folded into UTC';

    $b = body(hit($app, path => '/b/zeta'));
    like $b, qr{DATE=\[\]\s+ISO=\[\]\s+HUMAN=\[\]\s+UPD=\[\]}, 'undated: no fields';
}

{
    my $u = File::Temp->newdir;
    spew("$u/p.md", "---\ndate: 2026-01-01\nupdated: 2026-03-04 12:00Z\n---\n# P\n");
    my $app = mount(dir => "$u", template_dir => "$tmpl");
    my $b = body(hit($app, path => '/b/p'));
    like $b, qr{ISO=\[2026-01-01T00:00:00Z\]}, 'updated: the date stays';
    like $b, qr{UPDISO=\[2026-03-04T12:00:00Z\]},
        'updated: its own value, a space accepted for the T';
}

# ---- the arithmetic, against Time::Local -------------------------------------

{
    my @cases = (
        [ '1970-01-01', 0 ],
        [ '1969-12-31', -86400 ],
        [ '2000-02-29', Time::Local::timegm(0, 0, 0, 29, 1, 2000) ],
        [ '2024-12-31T23:59:59Z', Time::Local::timegm(59, 59, 23, 31, 11, 2024) ],
        [ '2026-06-30T23:30:00-01:00', Time::Local::timegm(0, 30, 0, 1, 6, 2026) ],
    );
    push @cases, [ '2100-03-01', Time::Local::timegm(0, 0, 0, 1, 2, 2100) ]
        if $Config::Config{ivsize} >= 8;
    for my $c (@cases) {
        my $d = File::Temp->newdir;
        spew("$d/x.md", "---\ndate: $c->[0]\n---\n# X\n");
        my $app = mount(dir => "$d", template_dir => "$tmpl");
        like body(hit($app, path => '/b/x')), qr{DATE=\[\Q$c->[1]\E\]},
            "$c->[0] is $c->[1]";
    }
}

# ---- what is refused ---------------------------------------------------------

for my $bad ('next tuesday', '2026-02-30', '2025-02-29', '2100-02-29', '2026-13-01',
             '2026-00-10', '2026-1-01', '2026-10-19T10:00',
             '2026-10-19T25:00Z', '2026-10-19T10:60Z', '2026-10-19T10:00+0200',
             '2026-10-19T10:00Zjunk', '2026/10/19') {
    my $d = File::Temp->newdir;
    spew("$d/bad.md", "---\ndate: $bad\n---\n# Bad\n");
    my $err = do { local $@; eval { mount(dir => "$d") }; $@ };
    like $err, qr{bad\.md has date '\Q$bad\E', which is not YYYY-MM-DD or ISO-8601},
        "date '$bad' croaks at boot naming the file";
}

{
    my $d = File::Temp->newdir;
    spew("$d/u.md", "---\ndate: 2026-10-19\nupdated: soon\n---\n# U\n");
    my $err = do { local $@; eval { mount(dir => "$d") }; $@ };
    like $err, qr{u\.md has updated 'soon'}, 'a bad updated croaks too';
}

{
    my $err = do { local $@; eval { mount(dir => "$tree", sort => 'newest') }; $@ };
    like $err, qr{markdown sort must be order, alpha or date, not 'newest'},
        'an unknown sort croaks';
}

{
    my $d = File::Temp->newdir;
    spew("$d/draft.md", "---\ndraft: 1\ndate: whenever\n---\n# D\n");
    spew("$d/ok.md", "# Ok\n");
    ok eval { mount(dir => "$d"); 1 }, 'a draft is skipped before its date is read'
        or diag $@;
}

# ---- reload ------------------------------------------------------------------

{
    my $d = File::Temp->newdir;
    spew("$d/r.md", "---\ndate: 2026-10-01\n---\n# R\n");
    my $app = mount(dir => "$d", template_dir => "$tmpl", reload => 1);
    like body(hit($app, path => '/b/r')), qr{ISO=\[2026-10-01T}, 'reload: first date';

    spew("$d/r.md", "---\ndate: 2026-10-02\n---\n# R\n");
    my $t = time + 5;
    utime $t, $t, "$d/r.md";
    like body(hit($app, path => '/b/r')), qr{ISO=\[2026-10-02T},
        'reload: a changed date is read again';

    spew("$d/r.md", "---\ndate: later\n---\n# R\n");
    $t += 5;
    utime $t, $t, "$d/r.md";
    my $err = do { local $@; eval { hit($app, path => '/b/r') }; $@ };
    like $err, qr{has date 'later'}, 'reload: a bad edit croaks on the request';
}

done_testing;
