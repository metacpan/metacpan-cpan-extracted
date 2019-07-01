package Telegram::Bot::Object::Animation;
$Telegram::Bot::Object::Animation::VERSION = '0.021';
# ABSTRACT: The base class for Telegram message 'Animation' type.


use Mojo::Base 'Telegram::Bot::Object::Base';
use Telegram::Bot::Object::PhotoSize;
use Carp qw/croak/;

has 'file_id';
has 'width';
has 'height';
has 'duration';
has 'thumb'; #PhotoSize
has 'file_name';
has 'mime_type';
has 'file_size';

sub fields {
  return { scalar => [qw/file_id width height duration file_name mime_type file_size/],
           'Telegram::Bot::Object::PhotoSize' => [qw/thumb/],
         };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Animation - The base class for Telegram message 'Animation' type.

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#animation> for details of the
attributes available for L<Telegram::Bot::Object::Animation> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
