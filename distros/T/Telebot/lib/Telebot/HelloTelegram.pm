package Telebot::HelloTelegram;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  push @{$self->commands->namespaces}, 'Telebot::Command';
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::HelloTelegram - Hello Telegram!

=head1 SYNOPSIS

    use Telebot::HelloTelegram;
    my $hello = Telebot::HelloTelegram->new;
    $hello->start;

=head1 DESCRIPTION

L<Telebot::HelloTelegram> is the default L<Telebot> application, used mostly for testing.

=head1 ATTRIBUTES

L<Telebot::HelloTelegram> inherits all attributes from L<Telebot>.

=head1 METHODS

L<Telebot::HelloTelegram> inherits all methods from L<Telebot> and implements the following new ones.

=head2 startup
    
    $hello->startup;

Creates a catch-all route that renders a text message.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<https://core.telegram.org/api>.

=cut
