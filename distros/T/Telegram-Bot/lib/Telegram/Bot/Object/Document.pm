package Telegram::Bot::Object::Document;
$Telegram::Bot::Object::Document::VERSION = '0.029';
# ABSTRACT: The base class for Telegram 'Document' objects


use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::PhotoSize;

has 'file_id';
has 'thumb'; #PhotoSize
has 'file_name';
has 'mime_type';
has 'file_size';

sub fields {
  return { scalar => [qw/file_id file_name mime_type file_size/],
           'Telegram::Bot::Object::PhotoSize' => [qw/thumb/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Document - The base class for Telegram 'Document' objects

=head1 VERSION

version 0.029

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#document> for details of the
attributes available for L<Telegram::Bot::Object::Document> objects.

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
