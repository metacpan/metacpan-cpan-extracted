package Telegram::Bot::Object::Video;
$Telegram::Bot::Object::Video::VERSION = '0.012';
# ABSTRACT: The base class for Telegram 'Video' object.

use Mojo::Base 'Telegram::Bot::Object::Base';

has 'file_id';
has 'width';
has 'height';
has 'duration';
has 'thumb';
has 'mime_type';
has 'file_size';
has 'caption';

sub fields {
  return { scalar => [qw/file_id width height duration mime_type file_size caption/],
           'Telegram::Bot::Message::PhotoSize' => [qw/thumb/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Video - The base class for Telegram 'Video' object.

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
