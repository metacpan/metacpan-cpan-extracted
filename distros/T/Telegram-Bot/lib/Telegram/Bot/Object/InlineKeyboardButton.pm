package Telegram::Bot::Object::InlineKeyboardButton;
$Telegram::Bot::Object::InlineKeyboardButton::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'InlineKeyboardButton' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::LoginUrl;
use Telegram::Bot::Object::CallbackGame;

has 'text';
has 'url';
has 'login_url'; #LoginUrl
has 'callback_data';
has 'switch_inline_query';
has 'switch_inline_query_current_chat';
has 'callback_game'; # CallbackGame
has 'pay';

sub fields {
  return { 'scalar' => [qw/text url callback_data switch_inline_query
                           switch_inline_query_current_chat switch_inline_query_current_chat
                           pay/],
  'Telegram::Bot::Object::LoginUrl'    => [qw/login_url/],
  'Telegram::Bot::Object::CallbackGame'=> [qw/callback_game/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::InlineKeyboardButton - The base class for Telegram 'InlineKeyboardButton' type objects

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#inlinekeyboardbutton> for details of the
attributes available for L<Telegram::Bot::Object::InlineKeyboardButton> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
