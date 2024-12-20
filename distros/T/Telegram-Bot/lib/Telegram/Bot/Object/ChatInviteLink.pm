package Telegram::Bot::Object::ChatInviteLink;
$Telegram::Bot::Object::ChatInviteLink::VERSION = '0.027';
# ABSTRACT: The base class for the Telegram type "ChatInviteLink".


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;

use Data::Dumper;

# basic message stuff
has 'creator'; # User

has 'invite_link'; # String
has 'creates_join_request';  # Boolean
has 'is_primary'; # Boolean
has 'is_revoked'; # Boolean
has 'name'; # String
has 'expire_date'; # Integer
has 'member_limit'; # Integer
has 'pending_join_request_count'; # Integer

sub fields {
  return {
          'scalar'                                      => [qw/invite_link creates_join_request is_primary is_revoked name expire_date member_limit pending_join_request_count/],
          'Telegram::Bot::Object::User'                 => [qw/creator/],
  };
}

sub arrays {
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ChatInviteLink - The base class for the Telegram type "ChatInviteLink".

=head1 VERSION

version 0.027

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chatinvitelink> for details of the
attributes available for L<Telegram::Bot::Object::ChatInviteLink> objects.

=head1 METHODS

=head2

Convenience methods

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
