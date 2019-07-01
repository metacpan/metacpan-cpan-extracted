package Telegram::Bot::Object::Contact;
$Telegram::Bot::Object::Contact::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'Contact' objects.


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'phone_number';
has 'first_name';
has 'last_name';
has 'user_id';

sub fields {
  return { scalar => [qw/phone_number first_name last_name user_id/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Contact - The base class for Telegram 'Contact' objects.

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chat> for details of the
attributes available for L<Telegram::Bot::Object::Contact> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
