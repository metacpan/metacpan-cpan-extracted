package Telegram::Bot::Object::VideoNote;
$Telegram::Bot::Object::VideoNote::VERSION = '0.026';
# ABSTRACT: The base class for Telegram 'VideoNote' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::PhotoSize;

has 'file_id';
has 'length';
has 'duration';
has 'mime_type';
has 'thumb'; #PhotoSize
has 'file_size';

sub fields {
  return { scalar                             => [qw/file_id length duration mime_type file_size/],
           'Telegram::Bot::Object::PhotoSize' => [qw/thumb /],

         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::VideoNote - The base class for Telegram 'VideoNote' type objects

=head1 VERSION

version 0.026

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#videonote> for details of the
attributes available for L<Telegram::Bot::Object::VideoNote> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=item *

Julien Fiegehenn <simbabque@cpan.org>

=item *

Albert Cester <albert.cester@web.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
