package Telebot;
use Mojo::Base 'Mojolicious', -signatures;

our $VERSION = '0.01';

sub startup ($self) {
    $self->pre_startup;

    $self->moniker('telebot');
    push @{$self->plugins->namespaces}, 'Telebot::Plugin';
    push @{$self->renderer->classes}, 'Telebot';
    push @{$self->routes->namespaces}, 'Telebot::Controller';
    
    my $config = $self->plugin('Config');
    $self->mode($config->{mode} || 'development');
    
    if (-e $self->home . '/logs') {
        $self->log(Mojo::Log->new(
            path => $self->home . '/logs/' . $self->mode . '.log',
        ));
    }

    $self->secrets($config->{secrets});
    
    $self->plugin('Utils');
    $self->plugin('DB');
    $self->plugin(Minion => {Pg => $config->{connection}});
    $self->plugin('Minion::Admin');    
    $self->plugin('Telegram');
    $self->plugin('Telegram::UI');
    $self->plugin('Hooks');

    my $r = $self->routes;
    $r->get('/')->to('tg#index');

    $self->post_startup();
}
sub pre_startup ($self) {$self}
sub post_startup ($self) {$self}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot - Mojolicious-based Telegram bot backend

=head1 SYNOPSIS

    # Application
    package MyBot;
    use Mojo::Base 'Telebot', -signatures;

    # startup is already defined but some code can be invoked in it

    sub pre_startup ($self) {
        # Code must be executed in the begining of startup
    }

    sub post_startup ($self) {
        # Code must be executed at the end of startup
    }

    1;

=head1 DESCRIPTION

Mojolicious and Minion based Telegram bot backend. This backend uses Webhook Telegram updates processing.

=head1 METHODS

L<Telebot> inherits all methods from L<Mojolicious> and implements the following new ones.

=head2 pre_startup
    
    $app->pre_startup;


This is your hook into the application, it will be called at the begining of Telebot application startup.
Meant to be overloaded in a subclass.

    sub pre_startup ($self) {...}

=head2 post_startup
    
    $app->post_startup;

This is your hook into the application, it will be called at the end of Telebot application startup.
Meant to be overloaded in a subclass.

    sub post_startup ($self) {...}

=head2 startup
    
    $app->startup;

This is main hook into the Telebot application, it will be called at application startup. Don't overload it without
need. You can use B<pre_startup> and B<post_startup> which called at the beginning and the end of B<startup>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://core.telegram.org/api>.

=cut

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

@@ tg/index.html.ep
% layout 'default';
% title 'tgbot';
<p>Telegram bot</p>
