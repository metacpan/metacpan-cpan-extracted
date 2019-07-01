package Telegram::Bot::Object::Chat;
$Telegram::Bot::Object::Chat::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'Chat' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::ChatPhoto;
use Telegram::Bot::Object::Message;

has 'id';
has 'type';
has 'title';
has 'username';
has 'first_name';
has 'last_name';
has 'all_members_are_administrators';
has 'photo'; #ChatPhoto
has 'description';
has 'invite_link';
has 'pinned_message'; #Message
has 'sticker_set_name';
has 'can_set_sticker_set';

sub fields {
  return {
          'scalar'                           => [qw/id type title username first_name
                                                    last_name all_members_are_administrators
                                                    description invite_link sticker_set_name
                                                    can_set_sticker_set/],
          'Telegram::Bot::Object::ChatPhoto' => [qw/photo/],
          'Telegram::Bot::Object::Message'   => [qw/pinned_message/],
        };
}


sub is_user {
  shift->id > 0;
}


sub is_group {
  shift->id < 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Chat - The base class for Telegram 'Chat' type objects

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chat> for details of the
attributes available for L<Telegram::Bot::Object::Chat> objects.

=head1 METHODS

=head2 is_user

Returns true is this is a chat is a single user.

=head2 is_group

Returns true if this is a chat is a group.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
