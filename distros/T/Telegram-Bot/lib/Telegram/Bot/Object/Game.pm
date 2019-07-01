package Telegram::Bot::Object::Game;
$Telegram::Bot::Object::Game::VERSION = '0.021';
# ABSTRACT: The base class for Telegram message 'Game' type.


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::PhotoSize;
use Telegram::Bot::Object::Animation;
use Telegram::Bot::Object::MessageEntity;

has 'title';
has 'description';
has 'photo'; # Array of PhotoSize
has 'text';
has 'text_entities'; #Array of MessageEntity
has 'animation'; #Animation

sub fields {
  return { scalar                                 => [qw/title description text/],
           'Telegram::Bot::Object::PhotoSize'     => [qw/photo/],
           'Telegram::Bot::Object::MessageEntity' => [qw/text_entities/],
           'Telegram::Bot::Object::Animation'     => [qw/animation/],
         };
}

sub arrays { qw/photo text_entities/ }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Game - The base class for Telegram message 'Game' type.

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#game> for details of the
attributes available for L<Telegram::Bot::Object::Game> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
