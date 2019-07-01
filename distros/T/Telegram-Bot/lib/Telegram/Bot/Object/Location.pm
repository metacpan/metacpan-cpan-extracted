package Telegram::Bot::Object::Location;
$Telegram::Bot::Object::Location::VERSION = '0.021';
# ABSTRACT: The base class for Telegram message 'Location' type.


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'longitude';
has 'latitude';

sub fields {
  return { scalar => [qw/longitude latitude/],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Location - The base class for Telegram message 'Location' type.

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#location> for details of the
attributes available for L<Telegram::Bot::Object::Location> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
