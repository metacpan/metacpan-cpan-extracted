#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use Test::More;
use PunkTest qw(hit);

# Punk::Plugin::CSP in development (PUNK_ENV at compile): the inline-handler scan over a rendered
# template, its escape hatch, the once-per-template memory, the stale-nonce
# warning, the switch that turns the scan off, and the violation-report
# endpoint with a report in either shape and with a body that is not one.

plan skip_all => 'Template::Stencil required' unless eval { require Template::Stencil; 1 };

my $DIR = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
spew("$DIR/inline.tmpl",  '<a onclick="go()">x</a>');
spew("$DIR/allowed.tmpl", '<!-- csp-allow-inline --><a onclick="go()">x</a>');
spew("$DIR/stale.tmpl",   '<script nonce="not-this-request">1</script>');
spew("$DIR/fresh.tmpl",   '<script nonce="{% csp_nonce %}">1</script>');
spew("$DIR/plain.tmpl",   '<p>nothing to see</p>');
spew("$DIR/empty.tmpl",   '');

my @log;
my %env = ('psgix.logger' => sub { push @log, $_[0] });
sub stats { my %s = Punk::Plugin::CSP->stats; return \%s }

{
    package DevApp;
    use Punk;
    plugin 'CSP' => { report_uri => '/csp-report' };
    views Stencil => { template_dir => $DIR };
    get '/inline'  => sub { $_[0]->render('inline') };
    get '/allowed' => sub { $_[0]->render('allowed') };
    get '/stale'   => sub { $_[0]->render('stale') };
    get '/fresh'   => sub { $_[0]->render('fresh') };
    get '/plain'   => sub { $_[0]->render('plain') };
    get '/empty'   => sub { $_[0]->render('empty') };
    package main;
}
my $app = do { local $ENV{PUNK_ENV} = 'development'; DevApp->to_app };

{
    my $before = stats();
    my $r = hit($app, path => '/inline', env => \%env);
    is($r->[0], 200, 'a template with an inline handler still renders');
    like($r->[2][0], qr/onclick/, 'untouched');
    my ($w) = grep { $_->{level} eq 'warn' } @log;
    like($w && $w->{message}, qr/inline has an inline `onclick=` handler, which a script nonce does NOT cover/,
        'and the development scan warns, naming the template and the handler');
    is(stats()->{warned} - $before->{warned}, 1, 'counted once');
    @log = ();
    hit($app, path => '/inline', env => \%env);
    is(scalar(grep { $_->{level} eq 'warn' } @log), 0, 'the same template is not warned about twice');
    is(stats()->{scanned} - $before->{scanned}, 2, 'though every render is scanned');
}
{
    @log = ();
    my $before = stats();
    hit($app, path => '/allowed', env => \%env);
    is(scalar(grep { $_->{level} eq 'warn' } @log), 0, 'csp-allow-inline in the template is the escape hatch');
    is(stats()->{warned}, $before->{warned}, 'nothing counted');
}
{
    @log = ();
    hit($app, path => '/stale', env => \%env);
    my ($w) = grep { $_->{level} eq 'warn' } @log;
    like($w && $w->{message}, qr/stale rendered a nonce that is not this request's/, 'a nonce that is not this request\'s is a cached page');
    @log = ();
    my $r = hit($app, path => '/fresh', env => \%env);
    my ($nonce) = ($r->[1]->[ (grep { $r->[1][$_] eq 'Content-Security-Policy' } 0 .. $#{ $r->[1] })[0] + 1 ] // '') =~ /'nonce-([^']+)'/;
    like($r->[2][0], qr/nonce="\Q$nonce\E"/, 'csp_nonce renders this request\'s nonce');
    is(scalar(grep { $_->{level} eq 'warn' } @log), 0, 'and that is not warned about');
    hit($app, path => '/plain', env => \%env);
    hit($app, path => '/empty', env => \%env);
    is(scalar(grep { $_->{level} eq 'warn' } @log), 0, 'nor a page with neither, nor an empty one');
}

# ---- the report endpoint -----------------------------------------------------
{
    my $before = stats();
    my $r = hit($app, method => 'POST', path => '/csp-report', env => \%env,
        body => '{"csp-report":{"document-uri":"https://a.example/p","blocked-uri":"https://evil.example/x","violated-directive":"script-src"}}',
        type => 'application/csp-report');
    is($r->[0], 204, 'a report is answered 204');
    is(scalar @{ $r->[2] }, 0, 'with no body');
    $r = hit($app, method => 'POST', path => '/csp-report', env => \%env,
        body => '{"document-uri":"https://a.example/p","blocked-uri":"inline"}', type => 'application/reports+json');
    is($r->[0], 204, 'the Reporting API shape is taken as it is');
    $r = hit($app, method => 'POST', path => '/csp-report', env => \%env, body => 'not json at all', type => 'application/csp-report');
    is($r->[0], 204, 'a body that is not a report is still 204');
    my $after = stats();
    is($after->{reports} - $before->{reports}, 3, 'three reports counted');
    is($after->{malformed} - $before->{malformed}, 1, 'one of them malformed');
}

# ---- the scan turned off, and not in development --------------------------------
{
    package OffApp;
    use Punk;
    plugin 'CSP' => { inline_check => 0 };
    views Stencil => { template_dir => $DIR };
    get '/inline' => sub { $_[0]->render('inline') };
    package ProdApp;
    use Punk;
    plugin 'CSP';
    views Stencil => { template_dir => $DIR };
    get '/inline' => sub { $_[0]->render('inline') };
    package main;
}
{
    my $before = stats();
    @log = ();
    my $off = do { local $ENV{PUNK_ENV} = 'development'; OffApp->to_app };
    my $prod = do { local $ENV{PUNK_ENV} = 'production'; ProdApp->to_app };
    hit($off, path => '/inline', env => \%env);
    hit($prod, path => '/inline', env => \%env);
    is(stats()->{scanned}, $before->{scanned}, 'inline_check => 0 and production scan nothing');
    is(scalar(grep { $_->{level} eq 'warn' } @log), 0, 'and warn about nothing');
}

done_testing;
