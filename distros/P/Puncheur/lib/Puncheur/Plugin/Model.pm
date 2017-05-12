package Puncheur::Plugin::Model;
use 5.010;
use strict;
use warnings;

use Carp;
use Plack::Util;

our @EXPORT = qw/model/;

sub init {
    my ($class, $app_class, $conf) = @_;

    my $model_class = "$app_class\::Models";
    Plack::Util::load_class($model_class);
    $model_class->register(base_dir => sub { $app_class->base_dir });
    $model_class->register(config   => sub { $app_class->config   });
}

my %INSTANCE;
sub model {
    my ($c, $name) = @_;
    my $instance = $INSTANCE{$c->app_name} ||= do {
        my $model_class = $c->app_name . '::Models';
        $model_class->instance
    };
    $name ? $instance->get($name) : $instance;
}

1;
