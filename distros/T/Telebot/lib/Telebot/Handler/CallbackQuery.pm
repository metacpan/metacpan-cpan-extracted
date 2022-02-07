package Telebot::Handler::CallbackQuery;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::CallbackQuery - Base class for telegram update part callback_query handler 

=head1 SYNOPSIS

    use Telebot::Handler::CallbackQuery;
    my $handler = Telebot::Handler::CallbackQuery->new(
        app => $app,
        payload => {
            id => 777,
            from => {
                id => 999,
                is_bot => \0,
                first_name => 'Vladimir',
                last_name => 'Lenin',
            },
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::CallbackQuery> is the base and default class for callback_query handler.
You can create your own handler in B<Handler/CallbackQuery.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::CallbackQuery> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::CallbackQuery> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update callback_query.
If not overloaded it dumps callback_query.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#callbackquery>.

=cut
