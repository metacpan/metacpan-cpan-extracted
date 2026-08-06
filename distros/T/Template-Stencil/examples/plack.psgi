#!perl
use strict;
use warnings;
use File::Basename ();
use Template::Stencil;

# Runs under any PSGI server: plackup examples/plack.psgi
# (dirname(__FILE__) keeps template resolution independent of cwd).

my $stencil = Template::Stencil->new(
    template_dir => File::Basename::dirname(__FILE__) . '/templates',
    wrapper      => 'wrapper.tmpl',
    stat_ttl     => -1,   # production: never re-stat cached templates
);

sub {
    my $env  = shift;
    my $body = $stencil->render('index', {
        title      => 'Stencil',
        js_scripts => ['app.js'],
        user       => { name => 'lnation' },
        items      => [ map { { name => " item $_ " } } 1 .. 10 ],
    });
    [ 200,
      [ 'Content-Type'   => 'text/html; charset=utf-8',
        'Content-Length' => length $body ],
      [ $body ] ];
};
