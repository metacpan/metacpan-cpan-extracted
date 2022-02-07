package Telebot::Plugin::Telegram;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::UserAgent;
use Carp 'croak';
use Mojo::Util qw(camelize);
use Mojo::Collection qw(c);
use Mojo::JSON qw(to_json);
use Scalar::Util qw(blessed);
use Mojo::Loader qw(load_class load_classes);

has ['app', 'ua', 'config'] => undef;
has allowed_updates => sub {c(qw(
    message edited_message
    channel_post edited_channel_post
    inline_query chosen_inline_result
    callback_query shipping_query pre_checkout_query
    poll poll_answer
    my_chat_member chat_member chat_join_request
))};
has handlers => sub {{}};

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);
    $self->ua(Mojo::UserAgent->new->inactivity_timeout(0));
    $self->config($app->config->{telegram} ? $app->config->{telegram} : $config || {});
    $self->config->{token} ||= $ENV{TEST_TELEBOT_TOKEN}; 
    croak 'Setup bot token in config' if !$self->config->{token};
    $self->allowed_updates(
        c(@{$self->config->{allowed_updates}})
    ) if $self->config->{allowed_updates};
    
    # Handlers
    load_classes("Telebot::Handler");
    for ($self->allowed_updates->each, 'update') {
        my $mod = "@{[ ref($app) ]}::Handler::@{[ camelize($_) ]}";
        if (my $e = load_class($mod)) {
            if (ref $e) {
                $app->log->error("Loading $mod exception: $e");
            }
            else {
                $self->handlers->{$_} = "Telebot::Handler::@{[ camelize($_) ]}";
                $app->log->info("$mod not found, Telebot::Handler::@{[ camelize($_) ]} loaded");
            }
        }
        else {
            $app->log->info("$mod loaded");
            $self->handlers->{$_} = $mod;
        }
    }

    # $app->tg->config()
    $app->helper('tg.config' => sub ($c) { $self->config });

    # $app->tg->handlers()
    $app->helper('tg.handlers' => sub ($c) { $self->handlers });
    
    # $app->tg->handler('message')
    $app->helper('tg.handler' => sub ($c, $type) { $self->handlers->{$type} });
    
    # $app->tg->gentoken()
    $app->helper('tg.gentoken' => sub ($c) { _gentoken() });
    
    # $app->tg->url('getMe')
    $app->helper('tg.url' => sub ($c, $method) {
        sprintf('%s/bot%s/%s',
            $self->config->{api_server} || 'https://api.telegram.org',
            $self->config->{token},
            $method)
    });
    
    # $app->tg->request()
    $app->helper('tg.request' => sub ($c, $method, $payload) {
        $self->app->log->info("Request $method");
        my $tx = $self->ua->build_tx(
            POST => $self->app->tg->url($method),
            _prepare_payload($payload, $app),
        );
        $tx = $self->ua->start($tx);
        if ($tx->res->code == 200) {
            return $tx->res->json;
        }
        else {
            $self->app->dump($tx->res);
            return $tx->res->json || {
                ok => 0,
                description => sprintf('Error %s during request', $tx->res->code),
            };
        }
    });
    
    # $app->tg->allowed_updates
    $app->helper('tg.allowed_updates' => sub ($c) {
        $self->allowed_updates;
    });
    
    # $app->tg->extract_commands($text, $entities)
    $app->helper('tg.extract_commands' => sub ($c, $text, $entities) {
        my @commands;
        for (grep {$_->{type} eq 'bot_command'} @{$entities||[]}) {
            my $cmd = substr($text, $_->{offset}+1, $_->{length});
            $cmd =~ /^([^@]+)@?([^@]+)?$/;
            push @commands, {
                command => $1,
                bot => $2,
            }
        }
        return c(@commands);
    });
    
    # Minion task
    $app->minion->add_task(update => 'Telebot::Task::Update');
    $app->minion->add_task($_ => 'Telebot::Task::UpdateField') for $self->allowed_updates->each;
    
}

sub _gentoken {
    join('', map {[0..9, 'a'..'z', 'A'..'Z']->[rand(62)]} (1..24))
}

sub _find_files {
    my ($var, $files) = @_;
    $files ||= {};
    if (ref $var eq 'HASH') {
        $var = {map {
            $_ => scalar _find_files($var->{$_}, $files)
        } keys %$var};
    }
    elsif (ref $var eq 'ARRAY') {
        $var = [map {
            scalar _find_files($_, $files)
        } @$var];
    }
    elsif (blessed $var && $var->isa('Mojo::Asset')) {
        my $name = _gentoken();
        $name = _gentoken() while exists $files->{$name};
        $files->{$name} = {file => $var};
        $var = "attach://$name";
    }
    return wantarray ? ($var, $files) : $var;
}

sub _prepare_payload {
    my ($payload) = @_;
    my ($data, $files) = _find_files($payload);
    if (keys %$files) {
        return (
            {'Content-Type' => 'multipart/form-data'},
            form => {
                (map {
                    $_ => ref $data->{$_} ? to_json($data->{$_}) : $data->{$_};
                } keys %$data),
                %$files,
            },
        );
    }
    else {
        return (
            {'Content-Type' => 'application/json'},
            json => $data || {},
        );
    }
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Plugin::Telegram - Telegram API plugin

=head1 SYNOPSIS

    # {
    #     message => 'Telebot::Handler::Message',
    #     poll => 'My::Bot::Handler::Poll',
    # }
    my $handlers = $app->tg->handlers();
    
    # 'Telebot::Handler::Message'
    my $message_handler = $app->tg->handler('message');
    
    # 'z8HcRt7Z6wj3E7bwk2pOZx4s'
    my $token = $app->tg->gentoken();

    # 'https://api.telegram.org/botTOKEN/getMe'
    my $url = $app->tg->url('getMe');
    
    # Requests to API
    my $response = $app->tg->request(getMe => {});
    my $response = $app->tg->request(sendMessage => {
        chat_id => 777,
        text => 'Hello, Telegram',
    });
    
    # c('message', 'poll')
    my $allowed_updates = $app->tg->allowed_updates;
    
    # c({
    #     command => 'start',
    #     bot => 'megabot',
    # }, {
    #     command => 'stop',
    #     bot => undef,
    # })
    $app->tg->extract_commands(
        'Please /start@megabot and /stop',
        [{
            type => 'command',
            offset => 7,
            length => 14,
        }, {
            type => 'command',
            offset => 26,
            length => 5,
        }]
    );
    
=head1 DESCRIPTION

L<Telebot::Plugin::Telegram> - plugin for working with Telegram API.

=head1 HELPERS

L<Telebot::Plugin::Telegram> implements the following helpers.

=head2 tg->handlers

Returns hash of registered handlers of update and it's parts.
Key - update or name of update field, value - name of handler module.

=head2 tg->handler

Returns name of handler module for update or update part.

=head2 tg->gentoken

Returns generated token (random string from alphabet symbols and digits)

=head2 tg->url

Returns URL for requesting Telegram API method

=head2 tg->request

Performs request to Telegram API

=head2 tg->allowed_updates

Return L<Mojo::Collection> of allowed updates (set of updates which Telegram sends to bot's webhook).

=head2 tg->extract_commands

Extract from text bot commands and return them as L<Mojo::Collection>

=head2 tg->config

Returns config of plugin.

=head1 METHODS

L<Telebot::Plugin::Telegram> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register
    
    my $tg = $plugin->register(Mojolicious->new);

Register plugin in Mojolicious application and define helpers.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
