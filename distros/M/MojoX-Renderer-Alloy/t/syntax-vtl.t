
use strict;
use warnings;

use utf8;

use Test::More tests => 25;

use Mojolicious::Lite;
use Mojo::ByteStream 'b';
use Test::Mojo;
use Cwd qw/abs_path/;

use File::Path qw( rmtree );
END { rmtree("t/tmp") };

# Silence
app->log->level('fatal');

use_ok('MojoX::Renderer::Alloy::Velocity');

plugin 'alloy_renderer' => {
    syntax => 'Velocity',
    template_options => {
        PRE_CHOMP => 1,
        POST_CHOMP => 1,
        TRIM => 1
    }
};

get '/exception' => 'error';

get '/with_include' => 'include';

get '/with_wrapper' => 'wrapper';

get '/unicode' => 'unicode';

get '/helpers' => 'helpers';

get '/unknown_helper' => 'unknown_helper';

get '/not_supported' => 'not_supported';

get '/on-disk' => 'foo';

get '/foo/:message' => 'index';


my $t = Test::Mojo->new;
$t->app->renderer->paths( [ abs_path("t/templates/vtl") ] );

# Exception
$t->get_ok('/exception')
    ->status_is(500)
    ->content_like(qr/parse error/);

# Normal rendering
$t->get_ok('/foo/hello')
    ->content_is("hello");

# With include
$t->get_ok('/with_include')
    ->content_like(qr/Hello\sInclude!Hallo/s);

# With wrapper
$t->get_ok('/with_wrapper')
    ->content_is("wrapped");

# Unicode
$t->get_ok('/unicode')
    ->content_is(
        b("привет")->to_string
    );

# Helpers
$t->get_ok('/helpers')
    ->content_is("/helpers");

# Unknown helper
$t->get_ok('/unknown_helper')
    ->status_is(500)
    ->content_like(qr/error.*unknown_helper/);

# Inlined template
$t->get_ok('/not_supported')
    ->status_is(500)
    ->content_like(qr/Inlined templates are not supported/);

# On Disk
$t->get_ok('/on-disk')
    ->content_is("4");

# Not found
$t->get_ok('/not_found')
    ->status_is(404)
    ->content_like(qr/not found/i);

__DATA__

@@ not_supported.html.vtl

Inlined templates are not supported

