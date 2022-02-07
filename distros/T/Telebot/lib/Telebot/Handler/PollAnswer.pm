package Telebot::Handler::PollAnswer;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::PollAnswer - Base class for telegram update part poll_answer handler 

=head1 SYNOPSIS

    use Telebot::Handler::PollAnswer;
    my $handler = Telebot::Handler::PollAnswer->new(
        app => $app,
        payload => {
            poll_id => 777,
            option_ids => [0],
            user => {
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

L<Telebot::Handler::PollAnswer> is the base and default class for poll_answer handler.
You can create your own handler in B<Handler/PollAnswer.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::PollAnswer> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::PollAnswer> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update poll_answer.
If not overloaded it dumps poll_answer.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#pollanswer>.

=cut
