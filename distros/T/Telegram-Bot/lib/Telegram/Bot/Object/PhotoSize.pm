package Telegram::Bot::Object::PhotoSize;
$Telegram::Bot::Object::PhotoSize::VERSION = '0.023';
# ABSTRACT: The base class for Telegram message 'PhotoSize' type.


use Mojo::Base 'Telegram::Bot::Object::Base';
use Carp qw/croak/;

has 'file_id';
has 'width';
has 'height';
has 'file_size';

sub fields {
  return { scalar => [qw/file_id width height file_size/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::PhotoSize - The base class for Telegram message 'PhotoSize' type.

=head1 VERSION

version 0.023

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#photosize> for details of the
attributes available for L<Telegram::Bot::Object::PhotoSize> objects.

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
