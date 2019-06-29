package Telegram::Bot::Object::PhotoSize;
$Telegram::Bot::Object::PhotoSize::VERSION = '0.012';
# ABSTRACT: The base class for Telegram message 'PhotoSize' type.

use Mojo::Base 'Telegram::Bot::Object::Base';
use Carp qw/croak/;

has 'file_id';
has 'width';
has 'height';
has 'file_size';

has 'image';

sub is_array { 1 }

sub fields {
  return { scalar => [qw/file_id width height file_size/]
         };
}

sub as_hashref {
  my $self = shift;
  my $hash = {};
  if ($self->image) {
    croak "no such file '". $self->image . "'." unless -e $self->image;
    $hash->{photo} = { file => $self->image };
  }

  return $hash;
}

sub send_method {
  return "Photo";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::PhotoSize - The base class for Telegram message 'PhotoSize' type.

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
