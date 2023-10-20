package Telegram::Bot::Object::ReplyKeyboardMarkup;
$Telegram::Bot::Object::ReplyKeyboardMarkup::VERSION = '0.024';
# ABSTRACT: The base class for Telegram 'ReplyKeyboardMarkup' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::KeyboardButton;

has 'keyboard';
has 'resize_keyboard';
has 'one_time_keyboard';
has 'selective';

sub fields {
  return { 'scalar' => [qw/resize_keyboard one_time_keyboard selective/],
           'Telegram::Bot::Object::KeyboardButton' => [qw/keyboard/],
         };
}

sub array_of_arrays {
  qw/keyboard/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ReplyKeyboardMarkup - The base class for Telegram 'ReplyKeyboardMarkup' type objects

=head1 VERSION

version 0.024

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#replykeyboardmarkup> for details of the
attributes available for L<Telegram::Bot::Object::InlineKeyboardMarkup> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
