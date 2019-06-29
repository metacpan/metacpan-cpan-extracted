package Telegram::Bot::Object::Audio;
$Telegram::Bot::Object::Audio::VERSION = '0.012';
# ABSTRACT: The base class for Telegram 'Audio' type objects

use Mojo::Base 'Telegram::Bot::Object::Base';

has 'file_id';
has 'duration';
has 'mime_type';
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

Telegram::Bot::Object::Audio - The base class for Telegram 'Audio' type objects

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
