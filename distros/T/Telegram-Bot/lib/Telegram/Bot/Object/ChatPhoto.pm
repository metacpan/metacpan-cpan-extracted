package Telegram::Bot::Object::ChatPhoto;
$Telegram::Bot::Object::ChatPhoto::VERSION = '0.021';
# ABSTRACT: The base class for Telegram 'ChatPhoto' type objects


use Mojo::Base 'Telegram::Bot::Object::Base';

has 'small_file_id';
has 'big_file_id';

sub fields {
  return {
          'scalar' => [qw/small_file_id big_file_id/],
        };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::ChatPhoto - The base class for Telegram 'ChatPhoto' type objects

=head1 VERSION

version 0.021

=head1 DESCRIPTION

See L<https://core.telegram.org/bots/api#chatphoto> for details of the
attributes available for L<Telegram::Bot::Object::ChatPhoto> objects.

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
