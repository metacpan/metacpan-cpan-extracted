package Telebot::Handler;
use Mojo::Base -base, -signatures;
has [qw(app payload update_id)] => undef, weak => 1;

sub run ($self) {
    $self->app->dump($self->payload);
} 

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler - Base class for telegram updates handlers

=head1 SYNOPSIS

    use Telebot::Handler;
    my $handler = Telebot::Handler->new(
        app => $app,
        payload => {},
        update_id => 1,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler> is the base class for L<Telebot> handlers.
After recieving update from telegram app process it with handlers.
Telebot uses handler for update itself and handlers for each part of
update (Message, Poll, etc). First of all Telebot after recieving
update calls handler for Update. And then depending on update content
one of handlers for update parts (Message, Poll, etc).
L<Telebot> defines default handlers for all types. You can define
your own handlers in Handler/ subdirectory. Handler must have the camelized
name of corresponding update part.

B<Handler/Update.pm> - for handling update itself

B<Handler/Message.pm> - for handling message part of update

B<Handler/CallbackQuery.pm> - for handling callback_query part of update

=head1 ATTRIBUTES

L<Telebot::Handler> implements the following attributes.

=head2 app

    my $app = $handler->app;

Reference to main Telebot application. Use it to call plugins and so on.
    
=head2 payload

    my $payload = $handler->payload;

Payload of telegram update (or part of update). Contain perl structure with data
recieved from webhook.
    
=head2 update_id

    my $update_id = $handler->update_id;

Each telegram update have update_id. This attribute contain update_id of processed telegram update.

=head1 METHODS

L<Telebot::Handler> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update (or part of it).
Not overloaded it dumps payload.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://core.telegram.org/api>.

=cut
