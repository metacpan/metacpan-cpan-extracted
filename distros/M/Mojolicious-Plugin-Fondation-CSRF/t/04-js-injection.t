#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use File::Temp qw(tempdir);
use Test::Mojo;
use FindBin;

# ── Test: CSRF static JS file is served and contains the patching logic ──

my $tmpdir = tempdir(CLEANUP => 1);

{
    package JSTestApp;
    use Mojo::Base 'Mojolicious', -signatures;

    sub startup ($self) {
        $self->home(Mojo::Home->new($tmpdir));
        $self->secrets(['test_secret_32_bytes_minimum']);

        $self->plugin('Fondation' => {
            dependencies => [
                { 'Fondation::SessionStore' => { store_dir => "$tmpdir/sessions" }},
                { 'Fondation::CSRF' => {
                    auto_protect => 0,
                    share_dir    => "$FindBin::Bin/../share",
                }},
            ],
        });
    }
}

my $t = Test::Mojo->new('JSTestApp');

subtest 'csrf.js is served as static file' => sub {
    $t->get_ok('/js/csrf.js')
      ->status_is(200)
      ->content_type_is('application/javascript');
};

subtest 'csrf.js contains X-CSRF-Token patching logic' => sub {
    my $js = $t->ua->get('/js/csrf.js')->res->body;
    ok $js =~ /X-CSRF-Token/, 'contains X-CSRF-Token header injection';
    ok $js =~ /window\.fetch/, 'patches window.fetch';
    ok $js =~ /XMLHttpRequest/, 'patches XMLHttpRequest';
};

done_testing;
