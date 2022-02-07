package Telebot::Handler::Message;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::Message - Base class for telegram update part message handler 

=head1 SYNOPSIS

    use Telebot::Handler::Message;
    my $handler = Telebot::Handler::Message->new(
        app => $app,
        payload => {
            message_id => 777,
            from => {
                id => 999,
                is_bot => \0,
                first_name => 'Vladimir',
                last_name => 'Lenin',
            },
            date => 1642266220,
            chat => {
                id => 444,
                type => 'private',
            },
            text => 'Hello Telegram',
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::Message> is the base and default class for message handler.
You can create your own handler in B<Handler/Message.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::Message> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::Message> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update message.
If not overloaded it dumps message.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#message>.

=cut
