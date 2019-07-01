package Telegram::Bot::Object::EncryptedPassportElement;
$Telegram::Bot::Object::EncryptedPassportElement::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'EncryptedPassportElement' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

# XXX Implement rest of this
# https://core.telegram.org/bots/api#encryptedpassportelement

has 'type';
has 'data';
has 'phone_number';
has 'email';

# XXX more here

sub fields {
  return { 'scalar' => [qw/type data phone_number email/] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::EncryptedPassportElement - The base class for Telegram 'EncryptedPassportElement' type objects

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#encryptedpassportelement> for details of the
attributes available for L<Telegram::Bot::Object::EncryptedPassportElement> objects.

Note that this type is not yet fully implemented.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
