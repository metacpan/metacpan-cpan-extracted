package Telegram::Bot::Object::Sticker;
$Telegram::Bot::Object::Sticker::VERSION = '0.012';
# ABSTRACT: The base class for Telegram message 'Sticker' type.

use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::PhotoSize;

has 'file_id';
has 'width';
has 'height';
has 'thumb';
has 'file_size';
has 'emoji';

sub fields {
  return { scalar => [qw/file_id width height file_size emoji/],
           object => [ { thumb => 'Telegram::Bot::Object::PhotoSize' } ],
           array  => [ ],
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Sticker - The base class for Telegram message 'Sticker' type.

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
