#!perl

# `vars` and `filters` on the markdown mount: a site's own values on every
# page (its name, its links), and its own Stencil filters, so a template_dir
# can share a header, a footer and a <head> with the rest of the site.

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();
use Encode ();

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
    print {$fh} Encode::encode('UTF-8', $text);
    close $fh;
}

my $tree = File::Temp->newdir;
spew("$tree/p.md", "---\ntitle: A \"quoted\" <title>\n---\n# P\n");

my $tmpl = File::Temp->newdir;
spew("$tmpl/wrapper.tmpl", "{% include _site %}|{% content %}");
spew("$tmpl/_site.tmpl",
     "NAME=[{% site_name %}] "
   . "LINKS=[{% for l in links %}{% l.label %}={% l.url %};{% end %}] "
   . "NEST=[{% social.x %}] ");
spew("$tmpl/page.tmpl", "TITLE=[{% title %}] JSON=[{% raw title | json %}]");
spew("$tmpl/app.css", "");

my $json = sub {
    require JSON::PP;
    my $s = JSON::PP->new->allow_nonref->encode($_[0]);
    $s =~ s/</\\u003c/g;
    $s;
};

my %vars = (
    site_name => 'Ünïcode Site',
    links     => [ { label => 'CPAN', url => 'https://metacpan.org/' },
                   { label => 'Mail', url => 'mailto:a@b' } ],
    social    => { x => '@me' },
);

my $n = 0;
sub build {
    my (%opt) = @_;
    my $pkg = 'MDVars' . ++$n;
    no strict 'refs';
    eval "package $pkg; use Punk; 1" or die $@;
    $pkg->punk_app->markdown('/d' => "$tree", search => 0, %opt);
    return $pkg->to_app;
}

{
    my $app = build(template_dir => "$tmpl", vars => \%vars,
                    filters => { json => $json });
    my $b = Encode::decode('UTF-8', body(hit($app, path => '/d/p')));
    like $b, qr{NAME=\[Ünïcode Site\]}, 'a string var reaches an included partial';
    like $b, qr{LINKS=\[CPAN=https://metacpan\.org/;Mail=mailto:a\@b;\]},
        'an array of hashes can be looped';
    like $b, qr{NEST=\[\@me\]}, 'a nested hash can be read';
    like $b, qr{TITLE=\[A &quot;quoted&quot; &lt;title&gt;\]},
        'the mount\'s own title is untouched';
    like $b, qr{JSON=\["A \\"quoted\\" \\u003ctitle>"\]},
        'a site filter runs, and raw keeps its output as it made it';

    my $nf = Encode::decode('UTF-8', body(hit($app, path => '/d/nope')));
    like $nf, qr{NAME=\[Ünïcode Site\]}, 'the 404 receives the vars too';

    $vars{site_name} = 'CHANGED';
    push @{ $vars{links} }, { label => 'X', url => 'x' };
    my $again = Encode::decode('UTF-8', body(hit($app, path => '/d/p')));
    like $again, qr{NAME=\[Ünïcode Site\]},
        'pages are built at boot: changing the hash later changes nothing';
}

{
    my %v = (site_name => 'Before', links => [], social => {});
    my $app = build(template_dir => "$tmpl", vars => \%v,
                    filters => { json => $json }, reload => 1);
    like body(hit($app, path => '/d/p')), qr{NAME=\[Before\]}, 'reload: first render';
    $v{site_name} = 'After';
    my $t = time + 5;
    utime $t, $t, "$tree/p.md";
    like body(hit($app, path => '/d/p')), qr{NAME=\[Before\]},
        'reload: a re-render still uses the vars as they were at boot';
}

# ---- what is refused -----------------------------------------------------------

for my $name (qw(title url meta canonical date_iso content kind)) {
    my $err = do { local $@; eval { build(vars => { $name => 'x' }) }; $@ };
    like $err, qr{markdown vars may not use '\Q$name\E', which the mount fills itself},
        "vars may not shadow '$name'";
}

{
    my $err = do { local $@; eval { build(vars => [1]) }; $@ };
    like $err, qr{markdown vars takes a hashref}, 'vars must be a hashref';
    $err = do { local $@; eval { build(filters => sub { 1 }) }; $@ };
    like $err, qr{markdown filters takes a hashref}, 'filters must be a hashref';
}

{
    my $err = do { local $@; eval { build(template_dir => "$tmpl") }; $@ };
    like $err, qr{json}, 'without the filter, a template using it fails at boot naming it';
}

# ---- the shipped templates are unaffected ------------------------------------------

{
    my $app = build(vars => { site_name => 'x', anything => [1, 2] }, title => 'S');
    like body(hit($app, path => '/d/p')), qr{<title>A &quot;quoted&quot; &lt;title&gt; - S</title>},
        'unused vars change nothing in the shipped wrapper';
}

done_testing;
