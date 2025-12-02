package Telegram::Bot::Object::Audio;
$Telegram::Bot::Object::Audio::VERSION = '0.029';
# ABSTRACT: The base class for Telegram 'Audio' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'file_id';
has 'duration';
has 'performer';
has 'title';
has 'mime_type';
has 'file_size';
has 'thumb'; #PhotoSize

sub fields {
  return { scalar => [qw/file_id duration performer title mime_type file_size/],
           'Telegram::Bot::Object::PhotoSize' => [qw/thumb/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Audio - The base class for Telegram 'Audio' type objects

=head1 VERSION

version 0.029

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#audio> for details of the
attributes available for L<Telegram::Bot::Object::Audio> objects.

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
