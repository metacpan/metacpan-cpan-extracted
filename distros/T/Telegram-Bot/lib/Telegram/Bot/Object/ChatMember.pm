package Telegram::Bot::Object::ChatMember;
$Telegram::Bot::Object::ChatMember::VERSION = '0.029';
# ABSTRACT: The base class for the Telegram type "ChatMember".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;

use Data::Dumper;

has 'status';
has 'user';

has 'can_add_web_page_previews';        # optional
has 'can_be_edited';                    # optional
has 'can_change_info';                  # optional
has 'can_delete_messages';              # optional
has 'can_delete_stories';               # optional
has 'can_edit_messages';                # optional
has 'can_edit_stories';                 # optional
has 'can_invite_users';                 # optional
has 'can_manage_chat';                  # optional
has 'can_manage_topics';                # optional
has 'can_manage_video_chats';           # optional
has 'can_manage_voice_chats';           # optional
has 'can_pin_messages';                 # optional
has 'can_post_messages';                # optional
has 'can_post_stories';                 # optional
has 'can_promote_members';              # optional
has 'can_restrict_members';             # optional
has 'can_send_audios';                  # optional
has 'can_send_documents';               # optional
has 'can_send_messages';                # optional
has 'can_send_other_messages';          # optional
has 'can_send_photos';                  # optional
has 'can_send_polls';                   # optional
has 'can_send_video_notes';             # optional
has 'can_send_videos';                  # optional
has 'can_send_voice_notes';             # optional
has 'custom_title';                     # optional
has 'is_anonymous';                     # optional
has 'until_date';                       # optional


sub fields {
  return {
        scalar => [qw/status can_add_web_page_previews can_be_edited
                can_change_info can_delete_messages can_delete_stories
                can_edit_messages can_edit_stories can_invite_users
                can_manage_chat can_manage_topics can_manage_video_chats
                can_manage_voice_chats can_pin_messages can_post_messages
                can_post_stories can_promote_members can_restrict_members
                can_send_audios can_send_documents can_send_messages
                can_send_other_messages can_send_photos can_send_polls
                can_send_video_notes can_send_videos can_send_voice_notes
                custom_title is_anonymous until_date/],
        'Telegram::Bot::Object::User' => [qw/user/],
  };
}

sub arrays {
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ChatMember - The base class for the Telegram type "ChatMember".

=head1 VERSION

version 0.029

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chatmember> for details of the
attributes available for L<Telegram::Bot::Object::ChatMember> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=item *

Julien Fiegehenn <simbabque@cpan.org>

=item *

Jess Robinson <jrobinson@cpan.org>

=item *

Albert Cester <albert.cester@web.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
