package Telebot::Handler::Poll;
use Mojo::Base 'Telebot::Handler', -signatures;

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Handler::Poll - Base class for telegram update part poll handler 

=head1 SYNOPSIS

    use Telebot::Handler::Poll;
    my $handler = Telebot::Handler::Poll->new(
        app => $app,
        payload => {
            id => 777,
            question => 'To be or not to be',
            options => [{
                text => 'To be',
                voter_count => 100,
            }, {
                text => 'Not to be',
                voter_count => 0,
            }, {
                text => 'Not sure',
                voter_count => 0,
            }],
            total_voter_count => 100,
            is_closed => \1,
            is_anonymous => \1,
            allows_multiple_answers => \0,
            type => 'regular',
        },
        update_id => 555,
    );
    $handler->run();

=head1 DESCRIPTION

L<Telebot::Handler::Poll> is the base and default class for poll handler.
You can create your own handler in B<Handler/Poll.pm>

=head1 ATTRIBUTES

L<Telebot::Handler::Poll> inherits all attributes from L<Telebot::Handler>.

=head1 METHODS

L<Telebot::Handler::Poll> inherits all methods from L<Telebot::Handler>.

=head2 run
    
    $handler->run;

This method is overloaded in inheritted classes and called for processing telegram update poll.
If not overloaded it dumps poll.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api#poll>.

=cut
