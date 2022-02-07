package Telebot::Handler::ChatMember;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::ChatMember - Base class for telegram update part chat_member handler 

=head1 SYNOPSIS

    use Telebot::Handler::ChatMember;
    my $handler = Telebot::Handler::ChatMember->new(
        app => $app,
        payload => {
            from => {
                id => 999,
                is_bot => \0,
                first_name => 'Vladimir',
                last_name => 'Lenin',
            },
            date => 1642266220,
            chat => {
                id => 444,
                type => 'channel',
                title => 'XXVII',
            },
            old_chat_member => {
                status => 'member',
                user => {
                    id => 999,
                    is_bot => \0,
                    first_name => 'Vladimir',
                    last_name => 'Lenin',
                },
            },
            new_chat_member => {
                status => 'administrator',
                user => {
                    id => 999,
                    is_bot => \0,
                    first_name => 'Vladimir',
                    last_name => 'Lenin',
                },
            },
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::ChatMember> is the base and default class for chat_member handler.
You can create your own handler in B<Handler/ChatMember.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::ChatMember> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::ChatMember> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update chat_member.
If not overloaded it dumps chat_member.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#chatmemberupdated>.

=cut
