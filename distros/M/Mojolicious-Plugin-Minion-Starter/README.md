# Mojolicious::Plugin::Minion::Starter

## NAME

Mojolicious::Plugin::Minion::Starter - start/stop minion workers with the Mojolicious server

## SYNOPSIS

use Mojolicious::Lite -signatures;

plugin Minion => { SQLite => 'sqlite:queue.db' };
plugin 'Minion::Starter' => { debug => 1, spawn => 2 };

app->minion->add_task(sleep => sub {
			  sleep 1;
		      });

get '/' => sub {
    my $c = shift;
    $c->render('text' => 'ok');
};

get '/enqueue' => sub {
    my $c = shift;

    my $j = $c->minion->enqueue('sleep');

    $c->render('json' => { job => $j });
};

get '/state/:id' => sub {
    my $c = shift;
    my $job = $c->minion->job($c->stash('id'));

    $c->render('json' => { job => $c->stash('id'), info => $job->info });
};

app->start;

## DESCRIPTION

This plugin starts and re-starts Minion workers every time the server gets started.

## OPTIONS

### spawn

Number of worker processes spawned.

### debug

Generate more debug messages.

## SEE ALSO

- Mojolicious
- Minion

## AUTHORS

Simone Cesano <scesano@cpan.org>

## COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

