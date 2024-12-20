package Telegram::Bot::Object::CallbackGame;
$Telegram::Bot::Object::CallbackGame::VERSION = '0.027';
# ABSTRACT: The base class for Telegram message 'CallbackGame' type.


use Mojo::Base 'Telegram::Bot::Object::Base';

# https://core.telegram.org/bots/api#callbackgame
# "A placeholder, currently holds no information. Use BotFather to set up your game"

sub fields {
  return { },
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::CallbackGame - The base class for Telegram message 'CallbackGame' type.

=head1 VERSION

version 0.027

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#callbackgame> for details of the
attributes available for L<Telegram::Bot::Object::CallbackGame> objects.

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
