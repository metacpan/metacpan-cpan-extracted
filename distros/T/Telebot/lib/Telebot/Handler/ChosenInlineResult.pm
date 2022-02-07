package Telebot::Handler::ChosenInlineResult;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::ChosenInlineResult - Base class for telegram update part chosen_inline_result handler 

=head1 SYNOPSIS

    use Telebot::Handler::ChosenInlineResult;
    my $handler = Telebot::Handler::ChosenInlineResult->new(
        app => $app,
        payload => {
            result_id => 777,
            from => {
                id => 999,
                is_bot => \0,
                first_name => 'Vladimir',
                last_name => 'Lenin',
            },
            query => 'That is the question',
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::ChosenInlineResult> is the base and default class for chosen_inline_result handler.
You can create your own handler in B<Handler/ChosenInlineResult.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::ChosenInlineResult> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::ChosenInlineResult> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update chosen_inline_result.
If not overloaded it dumps chosen_inline_result.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#choseninlineresult>.

=cut
