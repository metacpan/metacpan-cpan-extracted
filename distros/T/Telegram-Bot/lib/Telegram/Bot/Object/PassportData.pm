package Telegram::Bot::Object::PassportData;
$Telegram::Bot::Object::PassportData::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'PassportData' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::EncryptedPassportElement;
use Telegram::Bot::Object::EncryptedCredentials;

has 'data'; # Array of EncryptedPassportElement
has 'credentials'; # EncryptedCredentials

sub fields {
  return { 'Telegram::Bot::Object::EncryptedPassportElement' => [qw/data/],
           'Telegram::Bot::Object::EncryptedCredentials'     => [qw/credentials/],
         };
}
sub arrays {
  qw/data/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::PassportData - The base class for Telegram 'PassportData' type objects

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#passportdata> for details of the
attributes available for L<Telegram::Bot::Object::PassportData> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
