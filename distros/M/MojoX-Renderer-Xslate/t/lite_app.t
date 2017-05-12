use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojo::Loader qw(data_section);
use Mojolicious::Lite;

# Silence
app->log->level('fatal');

plugin 'xslate_renderer';

my $xslate = MojoX::Renderer::Xslate->build(
    mojo             => app,
    template_options => {
        syntax => 'TTerse',
        path   => [ data_section(__PACKAGE__) ],
    },
);
app->renderer->add_handler(tt => $xslate);
app->helper(die => sub { die 'died in helper' });

get '/exception'    => 'error';
get '/die_tpl'      => 'die';
get '/die_code'     => sub { die };
get '/with_include' => 'include';
get '/with_wrapper' => 'wrapper';
get '/foo/:message' => 'index';
get '/on-disk'      => 'foo';

my $t = Test::Mojo->new;

$t->get_ok('/exception')->status_is(500)->content_like(qr/error|^$/i);

# will "die" inside Xslate execution
$t->get_ok('/die_tpl')->status_is(500)->content_like(qr/error|^$/i);

# dies before Xslate does anything and Xslate will not be used since 
# internal mojo diagnostic templates are handled by default renderer
# (i.e.: EP renderer) 
$t->get_ok('/die_code')->status_is(500)->content_like(qr/error|^$/i);

$t->get_ok('/foo/hello')->content_like(qr/^hello\s*$/);
$t->get_ok('/with_include')->content_like(qr/^Hello\s*Include!Hallo\s*$/);
$t->get_ok('/with_wrapper')->content_like(qr/^wrapped\s*$/);
$t->get_ok('/on-disk')->content_is(4);
$t->get_ok('/not_found')->status_is(404)->content_like(qr/not found/i);

{
    my $old_default = app->renderer->default_handler();
    app->renderer->default_handler('tt');

    $t->get_ok('/exception')->status_is(500)->content_like(qr/error|^$/i);

    $t->get_ok('/die_tpl')->status_is(500)->content_like(qr/error|^$/i);

    # dies before Xslate does anything but then mojolicious wants to 
    # render the (optional and here unavailable) exception template
    # using Xslate engine which will not be able to locate that file
    $t->get_ok('/die_code')->status_is(500)->content_like(qr/error|^$/i);

    $t->get_ok('/foo/hello')->content_like(qr/^hello\s*$/);
    $t->get_ok('/with_include')->content_like(qr/^Hello\s*Include!Hallo\s*$/);
    $t->get_ok('/with_wrapper')->content_like(qr/^wrapped\s*$/);
    $t->get_ok('/on-disk')->content_is(4);
    $t->get_ok('/not_found')->status_is(404)->content_like(qr/not found/i);

    app->renderer->default_handler($old_default);
}

done_testing;

__DATA__

@@ error.html.tt
[% 1 + 1 %%]

@@ die.html.tt
[% c.die %]

@@ index.html.tt
[%- message -%]

@@ include.inc
Hello

@@ includes/include.inc
Hallo

@@ include.html.tt
[%- INCLUDE 'include.inc' -%]
Include!
[%- INCLUDE 'includes/include.inc' -%]

@@ layouts/layout.html.tt
w[%- content -%]d

@@ wrapper.html.tt
[%- WRAPPER 'layouts/layout.html.tt' -%]
rappe
[%- END -%]
