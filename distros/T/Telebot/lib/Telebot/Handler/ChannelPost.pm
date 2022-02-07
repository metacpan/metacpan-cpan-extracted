package Telebot::Handler::ChannelPost;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::ChannelPost - Base class for telegram update part channel_post handler 

=head1 SYNOPSIS

    use Telebot::Handler::ChannelPost;
    my $handler = Telebot::Handler::ChannelPost->new(
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
                type => 'channel',
                title => 'XXVII',
            },
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::ChannelPost> is the base and default class for channel_post handler.
You can create your own handler in B<Handler/ChannelPost.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::ChannelPost> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::ChannelPost> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update channel_post.
If not overloaded it dumps channel_post.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#message>.

=cut
