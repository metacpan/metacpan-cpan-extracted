package Telegram::Bot::Object::User;
$Telegram::Bot::Object::User::VERSION = '0.028';
# ABSTRACT: The base class for Telegram message 'User' type.


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'id';
has 'is_bot';
has 'first_name';
has 'last_name';     # optional
has 'username';      # optional
has 'language_code'; # optional

sub fields {
  return { scalar => [qw/id is_bot first_name last_name username language_code/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::User - The base class for Telegram message 'User' type.

=head1 VERSION

version 0.028

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#user> for details of the
attributes available for L<Telegram::Bot::Object::User> objects.

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
