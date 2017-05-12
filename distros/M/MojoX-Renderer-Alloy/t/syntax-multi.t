
use strict;
use warnings;

use utf8;

use Test::More tests => 12;

use Mojolicious::Lite;
use Test::Mojo;
use Cwd qw/abs_path/;

use File::Path qw( rmtree );
END { rmtree("t/tmp") };

# Silence
app->log->level('fatal');

use_ok('MojoX::Renderer::Alloy::TT');
use_ok('MojoX::Renderer::Alloy::Velocity');
use_ok('MojoX::Renderer::Alloy::Tmpl');
use_ok('MojoX::Renderer::Alloy::HTE');

plugin 'alloy_renderer' => {
    syntax => ':all',
    template_options => {
        PRE_CHOMP => 1,
        POST_CHOMP => 1,
        TRIM => 1
    }
};

my %engines = (
    TT => 'tt',
    Velocity => 'vtl',
    Tmpl => 'tmpl',
    HTE => 'hte'
);

while ( my ($h, $e) = each %engines ) {
    get "/\L$h" => sub {
        my $self = shift;

        $self->render(
            handler => $e,
            format => 'html',
            template => 'all'
        );
        $self->rendered;
    };
};


my $t = Test::Mojo->new;
$t->app->renderer->paths( [
    map {  abs_path("t/templates/$_") }
        qw( hte tmpl tt vtl )
] );

for my $h ( keys %engines ) {
    $t->get_ok("/\L$h")
        ->content_is("MojoX::Renderer::Alloy::$h");
};

