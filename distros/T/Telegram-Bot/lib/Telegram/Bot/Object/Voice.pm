package Telegram::Bot::Object::Voice;
$Telegram::Bot::Object::Voice::VERSION = '0.025';
# ABSTRACT: The base class for Telegram 'Voice' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'file_id';
has 'duration';
has 'mime_type';
has 'file_size';

sub fields {
  return { scalar => [qw/file_id duration mime_type file_size/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Voice - The base class for Telegram 'Voice' type objects

=head1 VERSION

version 0.025

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#voice> for details of the
attributes available for L<Telegram::Bot::Object::Voice> objects.

=head1 AUTHORS

=over 4

=item *

Justin Hawkins <justin@eatmorecode.com>

=item *

James Green <jkg@earth.li>

=item *

Julien Fiegehenn <simbabque@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by James Green.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
