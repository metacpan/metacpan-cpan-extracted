#!/usr/bin/env perl

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/lib";
}

use Mojolicious::Lite;

unshift @{app->commands->namespaces}, 'Command';

plugin Config => { file => 'main.conf' };

# NOTE: workaround
my %config = %{app->config};

app->config(\%config);

app->start;
