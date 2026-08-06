#!perl
use strict;
use warnings;
use File::Basename ();
use Hyperman;
use Template::Stencil;

# Template::Stencil on Hyperman. The engine is constructed lazily on a
# worker's first request - i.e. AFTER the prefork supervisor forks - so
# every worker owns its own engine and cache and nothing is shared
# (Template::Stencil's documented model; no locks anywhere).
#
# Zero-copy note: Hyperman's fast response path writev()s the header
# and the body SV's PV directly to the socket (hm_core.h, "no body
# copy"), and the body arrayref below holds the render buffer SV
# itself - so the rendered bytes are never copied between the template
# VM's output buffer and the kernel.

my $tdir = File::Basename::dirname(__FILE__) . '/templates';
my $stencil;   # per-worker, built post-fork on first use

my $app = sub {
    my $env = shift;
    $stencil //= Template::Stencil->new(
        template_dir => $tdir,
        wrapper      => 'wrapper.tmpl',
        stat_ttl     => -1,
    );
    my $body = $stencil->render('index', {
        title      => 'Stencil on Hyperman',
        js_scripts => ['app.js'],
        user       => { name => "worker $$" },
        items      => [ map { { name => " item $_ " } } 1 .. 10 ],
    });
    [ 200,
      [ 'Content-Type'   => 'text/html; charset=utf-8',
        'Content-Length' => length $body ],
      [ $body ] ];
};

Hyperman->run(
    app     => $app,
    port    => $ENV{STENCIL_PORT} || 8080,
    workers => $ENV{STENCIL_WORKERS} // 0,   # 1 = in-process dev mode
);
