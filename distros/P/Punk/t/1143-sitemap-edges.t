#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use Test::More;
use Punk::Plugin::Sitemap;

# The sitemap plugin's edges: the section keyword without a name or without
# code, a section returning a loc as a mapping with a lastmod, a loc that is
# not a rooted path, a section past the fifty-thousand cap, the plain
# document of an application that needs an index, the paths of an
# application that was never compiled, and a markdown page that asks not to
# be indexed.

sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

refuses(qr/sitemap needs a name - sitemap 'users' => sub/, 'the section keyword without a name',
    sub { eval q{ package SM1; use Punk; plugin 'Sitemap' => { base => 'https://e.example' }; sitemap(); 1 } or die $@ });
refuses(qr/sitemap 'users' needs a code reference that returns locations/, 'the section keyword without code',
    sub { eval q{ package SM2; use Punk; plugin 'Sitemap' => { base => 'https://e.example' }; sitemap('users' => 'nope'); 1 } or die $@ });

{
    package SMSec;
    use Punk;
    plugin 'Sitemap' => { base => 'https://e.example' };
    get '/' => sub { $_[0]->text('x') };
    sitemap('users' => sub {
        return ('/users/2', { loc => '/users/1', lastmod => '2024-01-02' }, { loc => undef },
                'https://elsewhere.example/x', 'relative', undef, { nothing => 1 });
    });
    package main;
}
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    SMSec->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(SMSec->punk_app);
    like($doc, qr{<loc>https://e\.example/users/1</loc>\s*<lastmod>2024-01-02</lastmod>}s, 'a loc given as a mapping carries its lastmod');
    like($doc, qr{<loc>https://e\.example/users/2</loc>}, 'a bare string is a loc');
    is(scalar(grep { /returned a loc that is not a rooted, same-origin path and is dropped: 'https:\/\/elsewhere\.example\/x'/ } @warn), 1,
        'a loc on another origin is dropped with a warning');
    is(scalar(grep { /dropped: 'relative'/ } @warn), 1, 'and so is one that is not rooted');
    unlike($doc, qr/elsewhere|relative/, 'neither is in the document');
}
{
    package SMBig;
    use Punk;
    plugin 'Sitemap' => { base => 'https://e.example' };
    get '/' => sub { $_[0]->text('x') };
    sitemap('everything' => sub { map { "/e/$_" } 1 .. 50_001 });
    package main;
}
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    SMBig->to_app;
    my $h = SMBig->punk_app;
    is(scalar(grep { /section 'everything' returned more than 50000 locations and is truncated there/ } @warn), 1,
        'a section past the cap is truncated with a warning');
    is(Punk::Plugin::Sitemap->_parts($h), 2, 'fifty thousand section locations and the routes make two parts');
    my $index = Punk::Plugin::Sitemap->_doc($h);
    like($index, qr{<sitemapindex xmlns=}, 'the plain document of a two-part application is the index');
    like($index, qr{<loc>https://e\.example/sitemap/1\.xml</loc>.*<loc>https://e\.example/sitemap/2\.xml</loc>}s, 'naming both parts');
}
{
    require Punk::App;
    my @p = Punk::Plugin::Sitemap->_paths(Punk::App->new);
    is_deeply(\@p, [], 'a bare registry has no router to read, so no paths');
}
SKIP: {
    skip 'needs Markdown::Simple with its C ABI', 2
        unless eval { require Markdown::Simple; Markdown::Simple->can('_abi_ptr') && Markdown::Simple::_abi_version() >= 1 }
            && eval { require Template::Stencil; Template::Stencil->can('_abi_ptr') };
    my $docs = File::Temp::tempdir(CLEANUP => 1);
    for my $f ([ 'index.md', "# Home\n" ], [ 'shown.md', "# Shown\n" ], [ 'hidden.md', "---\nrobots: noindex, follow\n---\n# Hidden\n" ]) {
        open my $fh, '>', "$docs/$f->[0]" or die; print $fh $f->[1]; close $fh;
    }
    package SMMd;
    use Punk;
    plugin 'Sitemap' => { base => 'https://e.example' };
    markdown '/docs' => $docs;
    package main;
    SMMd->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(SMMd->punk_app);
    like($doc, qr{<loc>https://e\.example/docs/shown</loc>}, 'a markdown page is listed');
    unlike($doc, qr{/docs/hidden}, 'but one whose robots line says noindex is not');
}

done_testing;
