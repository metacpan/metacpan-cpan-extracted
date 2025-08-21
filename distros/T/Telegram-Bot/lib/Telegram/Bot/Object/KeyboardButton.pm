package Telegram::Bot::Object::KeyboardButton;
$Telegram::Bot::Object::KeyboardButton::VERSION = '0.028';
# ABSTRACT: The base class for Telegram 'KeyboardButton' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'text';
has 'request_contact';
has 'request_location';

sub fields {
  return { 'scalar' => [qw/text request_contact request_location/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::KeyboardButton - The base class for Telegram 'KeyboardButton' type objects

=head1 VERSION

version 0.028

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#keyboardbutton> for details of the
attributes available for L<Telegram::Bot::Object::KeyboardButton> objects.

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
