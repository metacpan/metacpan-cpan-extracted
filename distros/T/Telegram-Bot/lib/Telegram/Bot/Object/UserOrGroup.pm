package Telegram::Bot::Object::UserOrGroup;
$Telegram::Bot::Object::UserOrGroup::VERSION = '0.012';
# ABSTRACT: The base class for Telegram message 'User' type.

use Mojo::Base 'Telegram::Bot::Object::Base';

use Telegram::Bot::Object::User;
use Telegram::Bot::Object::Group;

sub is_array { return; }

sub create_from_hash {
  my $class = shift;
  my $hash  = shift;
  if ($hash->{id} < 0) {
    return Telegram::Bot::Object::Group->create_from_hash($hash);
  }
  else {
    return Telegram::Bot::Object::User->create_from_hash($hash);
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::UserOrGroup - The base class for Telegram message 'User' type.

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
