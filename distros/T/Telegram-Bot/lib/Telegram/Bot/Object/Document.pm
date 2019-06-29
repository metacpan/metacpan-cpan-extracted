package Telegram::Bot::Object::Document;
$Telegram::Bot::Object::Document::VERSION = '0.012';
# ABSTRACT: The base class for Telegram 'Document' objects

use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::PhotoSize;

has 'file_id';
has 'thumb';
has 'file_name';
has 'mime_type';
has 'file_size';

sub is_array { return; }

sub fields {
  return { scalar => [qw/file_id file_name mime_type file_size/],
           'Telegram::Bot::Message::PhotoSize' => [qw/thumb/]
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Document - The base class for Telegram 'Document' objects

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
