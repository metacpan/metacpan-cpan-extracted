package Telebot::Plugin::Telegram::UI;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::UserAgent;
use Carp 'croak';
use Mojo::Util qw(camelize);
use Mojo::Collection qw(c);
use Mojo::JSON qw(to_json);
use Scalar::Util qw(blessed);
use Mojo::Loader qw(load_class load_classes);

has ['app'] => undef;

sub register {
    my ($self, $app, $config) = @_;

    $self->app($app);
    
    # $app->tg->ui->input(
    #     chat_id => 1,
    #     [text => 'Field instruction',]
    #     [placeholder => 'Hint text (<=64 symbols)',]
    # );
    $app->helper('tg.ui.input' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->input: No chat_id',
        } if !$options->{chat_id};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} // 'Input field',
            reply_markup => {
                force_reply => \1,
                input_field_placeholder => $options->{placeholder} || '',
            },
        });
        # save message_id for input field
    });
    # $app->tg->ui->choice(
    #     chat_id => 1,
    #     [text => 'Choice instruction',]
    #     buttons => [
    #         [ #Row1
    #             {
    #                 text => 'Button1',
    #                 callback_data => 'btn1',
    #             },
    #             {
    #                 text => 'Button2',
    #                 callback_data => 'btn2',
    #             },
    #         ],
    #         [ #Row2
    #             {
    #                 text => 'Button3',
    #                 callback_data => 'btn3',
    #             },
    #             {
    #                 text => 'Button4',
    #                 callback_data => 'btn4',
    #             },
    #         ]
    #     ],
    # );
    $app->helper('tg.ui.choice' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->choice: No chat_id',
        } if !$options->{chat_id};
        return {
            ok => 0,
            description => 'tg->ui->choice: No buttons',
        } if !@{$options->{buttons}||[]};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} // 'Select',
            reply_markup => {
                inline_keyboard => [map {
                    [map {$_} @$_]
                } @{$options->{buttons}||[]}],
                #resize_keyboard => \1,
                #one_time_keyboard => \1,
            },
        });
    });
    # $app->tg->ui->error(
    #     chat_id => 1,
    #     [text => 'Error text',]
    #     [reply_to => 1,]
    # );
    $app->helper('tg.ui.error' => sub ($c, @args) {
        my $options = _args(@args);
        return {
            ok => 0,
            description => 'tg->ui->error: No chat_id',
        } if !$options->{chat_id};
        $c->tg->request(sendMessage => {
            chat_id => $options->{chat_id},
            text => $options->{text} || 'Error',
            ($options->{reply_to} ? (reply_to_message_id => $options->{reply_to}) : ())
        });
    });
    
}

sub _args {
    ~~@_%2==0 ? {@_} : $_[0];
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Plugin::Telegram::UI - User intreface based on telegram API.

=head1 SYNOPSIS

    $app->tg->ui->input(
         chat_id => 111,
         text => 'Fill your name',
         placeholder => 'Your name here',
    );

    $app->tg->ui->choice(
        chat_id => 111,
        [text => 'Select next action',]
        buttons => [
            [
                {
                    text => 'Open beer',
                    callback_data => 'beer',
                },
                {
                    text => 'Code something',
                    callback_data => 'waste_time',
                },
            ],
            [
                {
                    text => 'Drink beer',
                    callback_data => 'pleasure',
                },
                {
                    text => 'Buy iPhone 115',
                    callback_data => 'waste_money',
                },
            ]
        ],
    );
    
    $app->tg->ui->error(
        chat_id => 111,
        text => 'Something unexpected',
        reply_to => 777,
    );

=head1 DESCRIPTION

L<Telebot::Plugin::Telegram::UI> - plugin defines some helpers
which will be more high level replacement of direct calls of
Telegram API.

B<IMPORTANT NOTE>. These helpers are EXPERIMENTAL. I'm not sure
they will not be changed or removed in future versions.

=head1 HELPERS

L<Telebot::Plugin::Telegram::UI> implements the following helpers.

=head2 tg->ui->input

Send to chat message which looks like input field.

=head2 tg->ui->choice

Send to chat message which looks like set of buttons with single choice.

=head2 tg->ui->error

Inform user about error in the Telegram chat.

=head1 METHODS

L<Telebot::Plugin::Telegram::UI> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

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
