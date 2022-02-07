package Telebot::Handler::Update;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::Update - Base class for telegram update handler.

=head1 SYNOPSIS

    use Telebot::Handler::Update;
    my $handler = Telebot::Handler::Update->new(
        app => $app,
        payload => {
            update_id => 555,
            pre_checkout_query => {
                id => 777,
                from => {
                    id => 999,
                    is_bot => \0,
                    first_name => 'Vladimir',
                    last_name => 'Lenin',
                },
                currency => 'RUB',
                total_amount => 10000,
                invoice_payload => 'Invoice#12345',
            },
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::Update> is the base and default class for update handler.
You can create your own handler in B<Handler/Update.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::Update> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::Update> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update.
If not overloaded it dumps update.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#update>.

=cut
